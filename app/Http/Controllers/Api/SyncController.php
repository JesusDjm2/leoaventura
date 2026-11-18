<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\SyncProgressRequest;
use App\Models\ActivityProgress;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class SyncController extends Controller
{
    /**
     * Devuelve el progreso sincronizado de los perfiles infantiles del padre autenticado.
     * Soporta filtro opcional ?child_id= validando estricto aislamiento de propietario.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $children = $user->children()
            ->select(['id', 'name', 'avatar_key', 'reading_level'])
            ->get();

        $authorizedChildIds = $children->pluck('id')->all();
        $childNamesById = $children->pluck('name', 'id');

        $requestedChildId = $request->query('child_id');
        if ($requestedChildId !== null && $requestedChildId !== '') {
            $childId = (int) $requestedChildId;
            if (! in_array($childId, $authorizedChildIds, true)) {
                abort(
                    Response::HTTP_FORBIDDEN,
                    "Acceso denegado: el perfil infantil con ID {$childId} no pertenece al usuario autenticado."
                );
            }
            $targetChildIds = [$childId];
        } else {
            $targetChildIds = $authorizedChildIds;
        }

        $records = ActivityProgress::query()
            ->select(['id', 'child_id', 'activity_id', 'score', 'stars', 'metadata', 'updated_at'])
            ->whereIn('child_id', $targetChildIds)
            ->orderByDesc('updated_at')
            ->get();

        return response()->json([
            'children' => $children->values()->all(),
            'total_completed' => $records->count(),
            'total_stars' => (int) $records->sum('stars'),
            'progress' => $records->map(static fn (ActivityProgress $row): array => [
                'id' => $row->id,
                'child_id' => $row->child_id,
                'child_name' => $childNamesById->get($row->child_id),
                'activity_id' => $row->activity_id,
                'score' => $row->score,
                'stars' => $row->stars,
                'metadata' => $row->metadata,
                'updated_at' => optional($row->updated_at)->toIso8601String(),
            ])->values()->all(),
        ], Response::HTTP_OK);
    }

    /**
     * Synchronize a batch of activity progress events using Last-Write-Wins (LWW).
     */
    public function syncProgress(SyncProgressRequest $request): JsonResponse
    {
        $user = $request->user();
        $events = $request->input('events');

        // Obtener todos los IDs de niños del padre autenticado para validación de aislamiento
        $authorizedChildIds = $user->children()->pluck('id')->all();

        $result = DB::transaction(function () use ($events, $authorizedChildIds) {
            $inserted = 0;
            $updated = 0;
            $deleted = 0;
            $ignored = 0;

            foreach ($events as $event) {
                $childId = (int) $event['child_id'];

                // Validación de aislamiento de datos: el perfil del niño debe pertenecer al padre
                if (! in_array($childId, $authorizedChildIds, true)) {
                    abort(Response::HTTP_FORBIDDEN, "Acceso denegado: el perfil infantil con ID {$childId} no pertenece al usuario autenticado.");
                }

                $activityId = (string) $event['activity_id'];
                $incomingUpdatedAt = Carbon::parse($event['updated_at']);
                $incomingDeletedAt = ! empty($event['deleted_at']) ? Carbon::parse($event['deleted_at']) : null;
                $score = (int) $event['score'];
                $stars = isset($event['stars']) ? (int) $event['stars'] : 0;
                $metadata = $event['metadata'] ?? null;

                // Buscar registro existente (incluidos los marcados con soft-delete)
                $existing = ActivityProgress::withTrashed()
                    ->where('child_id', $childId)
                    ->where('activity_id', $activityId)
                    ->first();

                if (! $existing) {
                    // Inserción directa
                    $record = new ActivityProgress();
                    $record->child_id = $childId;
                    $record->activity_id = $activityId;
                    $record->score = $score;
                    $record->stars = $stars;
                    $record->metadata = $metadata;
                    $record->created_at = $incomingUpdatedAt;
                    $record->updated_at = $incomingUpdatedAt;
                    $record->deleted_at = $incomingDeletedAt;

                    $record->timestamps = false;
                    $record->save();

                    if ($incomingDeletedAt) {
                        $deleted++;
                    } else {
                        $inserted++;
                    }
                } else {
                    // Estrategia Last-Write-Wins (LWW) basada en updated_at
                    $existingUpdatedAt = Carbon::parse($existing->updated_at);

                    if ($incomingUpdatedAt->greaterThan($existingUpdatedAt)) {
                        $existing->score = $score;
                        $existing->stars = $stars;
                        $existing->metadata = $metadata;
                        $existing->updated_at = $incomingUpdatedAt;
                        $existing->deleted_at = $incomingDeletedAt;

                        $existing->timestamps = false;
                        $existing->save();

                        if ($incomingDeletedAt) {
                            $deleted++;
                        } else {
                            $updated++;
                        }
                    } else {
                        // El evento es más antiguo o idéntico; se descarta por LWW
                        $ignored++;
                    }
                }
            }

            return [
                'total_events' => count($events),
                'inserted' => $inserted,
                'updated' => $updated,
                'deleted' => $deleted,
                'ignored' => $ignored,
            ];
        });

        return response()->json([
            'message' => 'Lote de progreso sincronizado exitosamente.',
            'summary' => $result,
        ], Response::HTTP_OK);
    }
}
