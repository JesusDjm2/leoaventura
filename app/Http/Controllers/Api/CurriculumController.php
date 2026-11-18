<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CurriculumLevel;
use Illuminate\Http\JsonResponse;

class CurriculumController extends Controller
{
    /**
     * Devuelve los niveles fonéticos del currículo junto con sus actividades dinámicas.
     * Endpoint público de solo lectura (sin PII), ideal para precarga offline-first.
     */
    public function levels(): JsonResponse
    {
        $levels = CurriculumLevel::query()
            ->select([
                'id',
                'code',
                'title',
                'phoneme',
                'letter',
                'example_word',
                'unit',
                'order_index',
                'audio_key',
            ])
            ->where('is_active', true)
            ->orderBy('order_index')
            ->with([
                'activities' => static function ($query): void {
                    $query->select([
                        'id',
                        'curriculum_level_id',
                        'activity_code',
                        'type',
                        'title',
                        'instruction',
                        'audio_key',
                        'order_index',
                        'payload',
                    ])->orderBy('order_index');
                },
            ])
            ->get();

        $response = response()->json([
            'version' => '1.0',
            'total_phonemes' => $levels->count(),
            'levels' => $levels->map(static fn (CurriculumLevel $level): array => [
                'id' => $level->id,
                'code' => $level->code,
                'title' => $level->title,
                'phoneme' => $level->phoneme,
                'letter' => $level->letter,
                'example_word' => $level->example_word,
                'unit' => $level->unit,
                'order_index' => $level->order_index,
                'audio_key' => $level->audio_key,
                'activities' => $level->activities->map(static fn ($activity): array => [
                    'id' => $activity->id,
                    'activity_code' => $activity->activity_code,
                    'type' => $activity->type,
                    'title' => $activity->title,
                    'instruction' => $activity->instruction,
                    'audio_key' => $activity->audio_key,
                    'order_index' => $activity->order_index,
                    'payload' => $activity->payload,
                ])->values()->all(),
            ])->values()->all(),
        ]);

        return $response
            ->header('Cache-Control', 'public, max-age=300, must-revalidate');
    }
}
