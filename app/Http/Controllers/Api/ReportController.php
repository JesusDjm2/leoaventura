<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityProgress;
use App\Models\Child;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

class ReportController extends Controller
{
    /**
     * Genera el reporte agregado de aprendizaje real para un perfil infantil
     * (protegido por auth:sanctum + child.owner).
     */
    public function show(Child $child): JsonResponse
    {
        $records = ActivityProgress::query()
            ->select(['activity_id', 'score', 'stars', 'metadata', 'updated_at'])
            ->where('child_id', $child->id)
            ->orderByDesc('updated_at')
            ->get();

        $byPhoneme = [];
        $totalMinutes = 0;

        foreach ($records as $row) {
            $letter = $this->extractLetter($row);
            if ($letter === null) {
                continue;
            }

            if (! isset($byPhoneme[$letter])) {
                $byPhoneme[$letter] = [
                    'phoneme' => $letter,
                    'score_sum' => 0,
                    'sessions' => 0,
                    'stars' => 0,
                ];
            }

            $byPhoneme[$letter]['score_sum'] += max(0, min(100, (int) $row->score));
            $byPhoneme[$letter]['sessions'] += 1;
            $byPhoneme[$letter]['stars'] += (int) $row->stars;

            $metaMinutes = is_array($row->metadata) && isset($row->metadata['duration_minutes'])
                ? (int) $row->metadata['duration_minutes']
                : 3;
            $totalMinutes += max(1, $metaMinutes);
        }

        $phonemes = array_values(array_map(
            static fn (array $bucket): array => [
                'phoneme' => $bucket['phoneme'],
                'mastery' => (int) round($bucket['score_sum'] / max(1, $bucket['sessions'])),
                'sessions' => $bucket['sessions'],
                'stars' => $bucket['stars'],
            ],
            $byPhoneme
        ));

        return response()->json([
            'child_id' => $child->id,
            'child_name' => $child->name,
            'period_label' => 'Progreso acumulado',
            'total_practice_minutes' => $totalMinutes,
            'total_stars' => (int) $records->sum('stars'),
            'total_sessions' => $records->count(),
            'generated_at' => Carbon::now('UTC')->toIso8601String(),
            'phonemes' => $phonemes,
        ], Response::HTTP_OK);
    }

    /**
     * Extrae la letra/grafema en mayúscula desde `metadata['letter']` o el código
     * de actividad (`act_m_tracing`, `act_enie_sound_match`, etc.).
     */
    private function extractLetter(ActivityProgress $row): ?string
    {
        if (is_array($row->metadata) && ! empty($row->metadata['letter'])) {
            return mb_strtoupper(trim((string) $row->metadata['letter']));
        }

        if (preg_match('/^act_([a-zñ]+)_/iu', (string) $row->activity_id, $matches) === 1) {
            $slug = mb_strtolower($matches[1]);
            if ($slug === 'enie') {
                return 'Ñ';
            }

            return mb_strtoupper($slug);
        }

        return null;
    }
}
