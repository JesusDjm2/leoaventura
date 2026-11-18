<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CurriculumActivity;
use App\Models\CurriculumLevel;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AdminCurriculumController extends Controller
{
    public function index(): View
    {
        $levels = CurriculumLevel::query()
            ->withCount('activities')
            ->orderBy('unit')
            ->orderBy('order_index')
            ->get();

        return view('admin.curriculum', [
            'levels' => $levels,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'letter' => ['required', 'string', 'max:4'],
            'phoneme' => ['required', 'string', 'max:20'],
            'example_word' => ['required', 'string', 'max:60'],
            'emoji' => ['nullable', 'string', 'max:10'],
            'unit' => ['required', 'integer', 'min:1', 'max:6'],
        ]);

        $letter = mb_strtolower(trim($validated['letter']));
        $slug = $letter === 'ñ' ? 'enie' : preg_replace('/[^a-z0-9]+/u', '_', $letter);
        $upper = mb_strtoupper($letter);
        $emoji = trim((string) ($validated['emoji'] ?? '⭐')) ?: '⭐';
        $audioKey = "fonemas/fonema_{$slug}";

        DB::transaction(function () use ($letter, $slug, $upper, $emoji, $audioKey, $validated): void {
            $nextOrder = ((int) CurriculumLevel::query()->max('order_index')) + 1;

            $level = CurriculumLevel::updateOrCreate(
                ['code' => "phoneme_{$slug}"],
                [
                    'title' => sprintf('Fonema %s - %s', $validated['phoneme'], $validated['example_word']),
                    'phoneme' => $validated['phoneme'],
                    'letter' => $letter,
                    'example_word' => $validated['example_word'],
                    'unit' => (int) $validated['unit'],
                    'order_index' => $nextOrder,
                    'audio_key' => $audioKey,
                    'is_active' => true,
                ]
            );

            CurriculumActivity::updateOrCreate(
                ['activity_code' => "act_{$slug}_tracing"],
                [
                    'curriculum_level_id' => $level->id,
                    'type' => CurriculumActivity::TYPE_TRACING,
                    'title' => "Traza la letra {$upper}",
                    'instruction' => "¡Hola! Traza la letra {$upper} con tu dedito.",
                    'audio_key' => $audioKey,
                    'order_index' => 1,
                    'payload' => [
                        'letter' => $letter,
                        'phoneme' => $validated['phoneme'],
                        'example_word' => $validated['example_word'],
                        'audio_key' => $audioKey,
                        'success_text' => sprintf(
                            '¡Excelente! Has trazado la letra %s. ¡%s como en %s!',
                            $upper,
                            $upper,
                            $validated['example_word']
                        ),
                    ],
                ]
            );

            CurriculumActivity::updateOrCreate(
                ['activity_code' => "act_{$slug}_sound_match"],
                [
                    'curriculum_level_id' => $level->id,
                    'type' => CurriculumActivity::TYPE_SOUND_MATCH,
                    'title' => "Encuentra el sonido {$validated['phoneme']}",
                    'instruction' => "Toca el dibujo que empieza con {$validated['phoneme']}.",
                    'audio_key' => $audioKey,
                    'order_index' => 2,
                    'payload' => [
                        'target_letter' => $upper,
                        'target_phoneme' => $validated['phoneme'],
                        'audio_key' => $audioKey,
                        'options' => [
                            [
                                'name' => $validated['example_word'],
                                'image_key' => "palabras/{$slug}_word",
                                'emoji' => $emoji,
                                'is_correct' => true,
                                'feedback_text' => "¡{$validated['example_word']}! Empieza con {$validated['phoneme']}.",
                                'audio_key' => "palabras/{$slug}",
                            ],
                            [
                                'name' => 'Sol',
                                'image_key' => 'palabras/s_sol',
                                'emoji' => '🌞',
                                'is_correct' => false,
                                'feedback_text' => 'Sol empieza con /s/.',
                                'audio_key' => 'palabras/sol',
                            ],
                            [
                                'name' => 'Luna',
                                'image_key' => 'palabras/l_luna',
                                'emoji' => '🌙',
                                'is_correct' => false,
                                'feedback_text' => 'Luna empieza con /l/.',
                                'audio_key' => 'palabras/luna',
                            ],
                        ],
                    ],
                ]
            );
        });

        return back()->with('status', "Fonema {$upper} ({$validated['example_word']}) guardado y publicado en la app.");
    }

    public function toggle(CurriculumLevel $level): RedirectResponse
    {
        $level->is_active = ! $level->is_active;
        $level->save();

        $state = $level->is_active ? 'activado' : 'ocultado';

        return back()->with('status', sprintf('Nivel "%s" %s correctamente.', mb_strtoupper($level->letter), $state));
    }

    public function update(Request $request, CurriculumLevel $level): RedirectResponse
    {
        $validated = $request->validate([
            'phoneme' => ['required', 'string', 'max:20'],
            'example_word' => ['required', 'string', 'max:60'],
            'unit' => ['required', 'integer', 'min:1', 'max:6'],
        ]);

        $level->update([
            'phoneme' => $validated['phoneme'],
            'example_word' => $validated['example_word'],
            'unit' => (int) $validated['unit'],
            'title' => sprintf('Fonema %s - %s', $validated['phoneme'], $validated['example_word']),
        ]);

        return back()->with('status', sprintf('Nivel "%s" actualizado.', mb_strtoupper($level->letter)));
    }
}
