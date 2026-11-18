<?php

namespace Database\Seeders;

use App\Models\CurriculumActivity;
use App\Models\CurriculumLevel;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CurriculumSeeder extends Seeder
{
    /**
     * Inserta de forma idempotente los 20 fonemas del currículo de alfabetización
     * inicial y sus actividades dinámicas (trazado y emparejamiento fonema-imagen).
     */
    public function run(): void
    {
        $phonemes = $this->curriculumPhonemes();

        DB::transaction(function () use ($phonemes): void {
            foreach ($phonemes as $index => $item) {
                $order = $index + 1;
                $letter = $item['letter'];
                $slugLetter = $letter === 'ñ' ? 'enie' : $letter;
                $audioKey = "fonemas/fonema_{$slugLetter}";

                $level = CurriculumLevel::updateOrCreate(
                    ['code' => "phoneme_{$slugLetter}"],
                    [
                        'title' => sprintf('Fonema %s - %s', $item['phoneme'], $item['word']),
                        'phoneme' => $item['phoneme'],
                        'letter' => $letter,
                        'example_word' => $item['word'],
                        'unit' => $item['unit'],
                        'order_index' => $order,
                        'audio_key' => $audioKey,
                        'is_active' => true,
                    ]
                );

                // Actividad 1: Trazado táctil dinámico
                CurriculumActivity::updateOrCreate(
                    ['activity_code' => "act_{$slugLetter}_tracing"],
                    [
                        'curriculum_level_id' => $level->id,
                        'type' => CurriculumActivity::TYPE_TRACING,
                        'title' => sprintf('Traza la letra %s', mb_strtoupper($letter)),
                        'instruction' => sprintf(
                            '¡Hola! Traza la letra %s con tu dedito.',
                            mb_strtoupper($letter)
                        ),
                        'audio_key' => $audioKey,
                        'order_index' => 1,
                        'payload' => [
                            'letter' => $letter,
                            'phoneme' => $item['phoneme'],
                            'example_word' => $item['word'],
                            'audio_key' => $audioKey,
                            'instruction_audio' => "instrucciones/instruccion_traza_letra_{$slugLetter}",
                            'success_text' => sprintf(
                                '¡Excelente! Has trazado la letra %s. ¡%s como en %s!',
                                mb_strtoupper($letter),
                                $item['sound_cue'],
                                $item['word']
                            ),
                            'checkpoints' => $item['checkpoints'],
                        ],
                    ]
                );

                // Actividad 2: Emparejamiento de fonema con imagen
                $distractors = $this->pickDistractors($phonemes, $index);
                $options = array_merge(
                    [[
                        'name' => $item['word'],
                        'image_key' => "palabras/{$slugLetter}_{$item['image_slug']}",
                        'emoji' => $item['emoji'],
                        'is_correct' => true,
                        'feedback_text' => sprintf('¡%s! Empieza con %s.', $item['word'], $item['phoneme']),
                        'audio_key' => "palabras/{$item['image_slug']}",
                    ]],
                    array_map(static fn (array $d): array => [
                        'name' => $d['word'],
                        'image_key' => sprintf('palabras/%s_%s', $d['letter'] === 'ñ' ? 'enie' : $d['letter'], $d['image_slug']),
                        'emoji' => $d['emoji'],
                        'is_correct' => false,
                        'feedback_text' => sprintf('%s empieza con %s.', $d['word'], $d['phoneme']),
                        'audio_key' => "palabras/{$d['image_slug']}",
                    ], $distractors)
                );

                CurriculumActivity::updateOrCreate(
                    ['activity_code' => "act_{$slugLetter}_sound_match"],
                    [
                        'curriculum_level_id' => $level->id,
                        'type' => CurriculumActivity::TYPE_SOUND_MATCH,
                        'title' => sprintf('Encuentra el sonido %s', $item['phoneme']),
                        'instruction' => sprintf('Toca el dibujo que empieza con %s.', $item['phoneme']),
                        'audio_key' => $audioKey,
                        'order_index' => 2,
                        'payload' => [
                            'target_letter' => mb_strtoupper($letter),
                            'target_phoneme' => $item['phoneme'],
                            'audio_key' => $audioKey,
                            'options' => $options,
                        ],
                    ]
                );
            }
        });
    }

    /**
     * Selecciona 2 distractores deterministas con fonemas distintos al objetivo.
     *
     * @param  array<int, array<string, mixed>>  $phonemes
     * @return array<int, array<string, mixed>>
     */
    private function pickDistractors(array $phonemes, int $currentIndex): array
    {
        $total = count($phonemes);
        $first = $phonemes[($currentIndex + 5) % $total];
        $second = $phonemes[($currentIndex + 11) % $total];

        return [$first, $second];
    }

    /**
     * Catálogo pedagógico de los 20 fonemas esenciales de alfabetización inicial en español.
     *
     * @return array<int, array<string, mixed>>
     */
    private function curriculumPhonemes(): array
    {
        return [
            // Unidad 1: Vocales (5)
            [
                'unit' => 1, 'letter' => 'a', 'phoneme' => '/a/', 'sound_cue' => 'Aaa',
                'word' => 'Árbol', 'image_slug' => 'arbol', 'emoji' => '🌳',
                'checkpoints' => [
                    ['x' => 0.50, 'y' => 0.25], ['x' => 0.38, 'y' => 0.50], ['x' => 0.28, 'y' => 0.75],
                    ['x' => 0.62, 'y' => 0.50], ['x' => 0.72, 'y' => 0.75], ['x' => 0.50, 'y' => 0.58],
                ],
            ],
            [
                'unit' => 1, 'letter' => 'e', 'phoneme' => '/e/', 'sound_cue' => 'Eee',
                'word' => 'Elefante', 'image_slug' => 'elefante', 'emoji' => '🐘',
                'checkpoints' => [
                    ['x' => 0.36, 'y' => 0.50], ['x' => 0.64, 'y' => 0.50], ['x' => 0.56, 'y' => 0.34],
                    ['x' => 0.36, 'y' => 0.38], ['x' => 0.36, 'y' => 0.64], ['x' => 0.58, 'y' => 0.72],
                ],
            ],
            [
                'unit' => 1, 'letter' => 'i', 'phoneme' => '/i/', 'sound_cue' => 'Iii',
                'word' => 'Isla', 'image_slug' => 'isla', 'emoji' => '🏝️',
                'checkpoints' => [
                    ['x' => 0.50, 'y' => 0.25], ['x' => 0.50, 'y' => 0.45],
                    ['x' => 0.50, 'y' => 0.60], ['x' => 0.50, 'y' => 0.75],
                ],
            ],
            [
                'unit' => 1, 'letter' => 'o', 'phoneme' => '/o/', 'sound_cue' => 'Ooo',
                'word' => 'Oso', 'image_slug' => 'oso', 'emoji' => '🐻',
                'checkpoints' => [
                    ['x' => 0.50, 'y' => 0.28], ['x' => 0.32, 'y' => 0.50],
                    ['x' => 0.50, 'y' => 0.72], ['x' => 0.68, 'y' => 0.50],
                ],
            ],
            [
                'unit' => 1, 'letter' => 'u', 'phoneme' => '/u/', 'sound_cue' => 'Uuu',
                'word' => 'Uva', 'image_slug' => 'uva', 'emoji' => '🍇',
                'checkpoints' => [
                    ['x' => 0.32, 'y' => 0.35], ['x' => 0.34, 'y' => 0.62],
                    ['x' => 0.50, 'y' => 0.74], ['x' => 0.66, 'y' => 0.62], ['x' => 0.68, 'y' => 0.35],
                ],
            ],

            // Unidad 2: Consonantes Iniciales (5)
            [
                'unit' => 2, 'letter' => 'm', 'phoneme' => '/m/', 'sound_cue' => 'Mmm',
                'word' => 'Mamá', 'image_slug' => 'mama', 'emoji' => '👩',
                'checkpoints' => [
                    ['x' => 0.22, 'y' => 0.35], ['x' => 0.22, 'y' => 0.55], ['x' => 0.22, 'y' => 0.75],
                    ['x' => 0.36, 'y' => 0.35], ['x' => 0.50, 'y' => 0.55], ['x' => 0.50, 'y' => 0.75],
                    ['x' => 0.64, 'y' => 0.35], ['x' => 0.78, 'y' => 0.55], ['x' => 0.78, 'y' => 0.75],
                ],
            ],
            [
                'unit' => 2, 'letter' => 'p', 'phoneme' => '/p/', 'sound_cue' => 'Ppp',
                'word' => 'Pato', 'image_slug' => 'pato', 'emoji' => '🦆',
                'checkpoints' => [
                    ['x' => 0.35, 'y' => 0.30], ['x' => 0.35, 'y' => 0.55], ['x' => 0.35, 'y' => 0.78],
                    ['x' => 0.55, 'y' => 0.30], ['x' => 0.65, 'y' => 0.42], ['x' => 0.52, 'y' => 0.54],
                ],
            ],
            [
                'unit' => 2, 'letter' => 's', 'phoneme' => '/s/', 'sound_cue' => 'Sss',
                'word' => 'Sol', 'image_slug' => 'sol', 'emoji' => '🌞',
                'checkpoints' => [
                    ['x' => 0.64, 'y' => 0.30], ['x' => 0.48, 'y' => 0.26], ['x' => 0.34, 'y' => 0.38],
                    ['x' => 0.50, 'y' => 0.50], ['x' => 0.66, 'y' => 0.62], ['x' => 0.50, 'y' => 0.74],
                    ['x' => 0.34, 'y' => 0.70],
                ],
            ],
            [
                'unit' => 2, 'letter' => 'l', 'phoneme' => '/l/', 'sound_cue' => 'Lll',
                'word' => 'Luna', 'image_slug' => 'luna', 'emoji' => '🌙',
                'checkpoints' => [
                    ['x' => 0.40, 'y' => 0.25], ['x' => 0.40, 'y' => 0.50],
                    ['x' => 0.40, 'y' => 0.75], ['x' => 0.62, 'y' => 0.75],
                ],
            ],
            [
                'unit' => 2, 'letter' => 't', 'phoneme' => '/t/', 'sound_cue' => 'Ttt',
                'word' => 'Tortuga', 'image_slug' => 'tortuga', 'emoji' => '🐢',
                'checkpoints' => [
                    ['x' => 0.50, 'y' => 0.25], ['x' => 0.50, 'y' => 0.50], ['x' => 0.50, 'y' => 0.75],
                    ['x' => 0.34, 'y' => 0.40], ['x' => 0.66, 'y' => 0.40],
                ],
            ],

            // Unidad 3: Consonantes Intermedias (5)
            [
                'unit' => 3, 'letter' => 'n', 'phoneme' => '/n/', 'sound_cue' => 'Nnn',
                'word' => 'Nube', 'image_slug' => 'nube', 'emoji' => '☁️',
                'checkpoints' => [
                    ['x' => 0.32, 'y' => 0.35], ['x' => 0.32, 'y' => 0.75],
                    ['x' => 0.50, 'y' => 0.35], ['x' => 0.68, 'y' => 0.55], ['x' => 0.68, 'y' => 0.75],
                ],
            ],
            [
                'unit' => 3, 'letter' => 'd', 'phoneme' => '/d/', 'sound_cue' => 'Ddd',
                'word' => 'Dado', 'image_slug' => 'dado', 'emoji' => '🎲',
                'checkpoints' => [
                    ['x' => 0.64, 'y' => 0.24], ['x' => 0.64, 'y' => 0.50], ['x' => 0.64, 'y' => 0.75],
                    ['x' => 0.48, 'y' => 0.46], ['x' => 0.34, 'y' => 0.58], ['x' => 0.50, 'y' => 0.72],
                ],
            ],
            [
                'unit' => 3, 'letter' => 'f', 'phoneme' => '/f/', 'sound_cue' => 'Fff',
                'word' => 'Flor', 'image_slug' => 'flor', 'emoji' => '🌸',
                'checkpoints' => [
                    ['x' => 0.62, 'y' => 0.26], ['x' => 0.48, 'y' => 0.30], ['x' => 0.46, 'y' => 0.52],
                    ['x' => 0.46, 'y' => 0.75], ['x' => 0.34, 'y' => 0.48], ['x' => 0.60, 'y' => 0.48],
                ],
            ],
            [
                'unit' => 3, 'letter' => 'r', 'phoneme' => '/r/', 'sound_cue' => 'Rrr',
                'word' => 'Ratón', 'image_slug' => 'raton', 'emoji' => '🐭',
                'checkpoints' => [
                    ['x' => 0.38, 'y' => 0.34], ['x' => 0.38, 'y' => 0.55], ['x' => 0.38, 'y' => 0.75],
                    ['x' => 0.50, 'y' => 0.36], ['x' => 0.64, 'y' => 0.36],
                ],
            ],
            [
                'unit' => 3, 'letter' => 'b', 'phoneme' => '/b/', 'sound_cue' => 'Bbb',
                'word' => 'Ballena', 'image_slug' => 'ballena', 'emoji' => '🐳',
                'checkpoints' => [
                    ['x' => 0.36, 'y' => 0.24], ['x' => 0.36, 'y' => 0.50], ['x' => 0.36, 'y' => 0.75],
                    ['x' => 0.54, 'y' => 0.48], ['x' => 0.64, 'y' => 0.60], ['x' => 0.50, 'y' => 0.74],
                ],
            ],

            // Unidad 4: Consonantes Avanzadas (5)
            [
                'unit' => 4, 'letter' => 'c', 'phoneme' => '/k/', 'sound_cue' => 'Ccc',
                'word' => 'Casa', 'image_slug' => 'casa', 'emoji' => '🏠',
                'checkpoints' => [
                    ['x' => 0.66, 'y' => 0.34], ['x' => 0.48, 'y' => 0.28], ['x' => 0.34, 'y' => 0.50],
                    ['x' => 0.48, 'y' => 0.72], ['x' => 0.66, 'y' => 0.66],
                ],
            ],
            [
                'unit' => 4, 'letter' => 'g', 'phoneme' => '/g/', 'sound_cue' => 'Ggg',
                'word' => 'Gato', 'image_slug' => 'gato', 'emoji' => '🐱',
                'checkpoints' => [
                    ['x' => 0.62, 'y' => 0.34], ['x' => 0.42, 'y' => 0.34], ['x' => 0.34, 'y' => 0.50],
                    ['x' => 0.56, 'y' => 0.58], ['x' => 0.62, 'y' => 0.70], ['x' => 0.42, 'y' => 0.80],
                ],
            ],
            [
                'unit' => 4, 'letter' => 'j', 'phoneme' => '/x/', 'sound_cue' => 'Jjj',
                'word' => 'Jirafa', 'image_slug' => 'jirafa', 'emoji' => '🦒',
                'checkpoints' => [
                    ['x' => 0.54, 'y' => 0.24], ['x' => 0.54, 'y' => 0.44], ['x' => 0.54, 'y' => 0.66],
                    ['x' => 0.46, 'y' => 0.78], ['x' => 0.36, 'y' => 0.74],
                ],
            ],
            [
                'unit' => 4, 'letter' => 'v', 'phoneme' => '/v/', 'sound_cue' => 'Vvv',
                'word' => 'Vaca', 'image_slug' => 'vaca', 'emoji' => '🐄',
                'checkpoints' => [
                    ['x' => 0.30, 'y' => 0.32], ['x' => 0.40, 'y' => 0.54], ['x' => 0.50, 'y' => 0.74],
                    ['x' => 0.60, 'y' => 0.54], ['x' => 0.70, 'y' => 0.32],
                ],
            ],
            [
                'unit' => 4, 'letter' => 'ñ', 'phoneme' => '/ɲ/', 'sound_cue' => 'Ñññ',
                'word' => 'Ñandú', 'image_slug' => 'nandu', 'emoji' => '🐦',
                'checkpoints' => [
                    ['x' => 0.32, 'y' => 0.40], ['x' => 0.32, 'y' => 0.75], ['x' => 0.50, 'y' => 0.42],
                    ['x' => 0.68, 'y' => 0.58], ['x' => 0.68, 'y' => 0.75],
                    ['x' => 0.36, 'y' => 0.26], ['x' => 0.64, 'y' => 0.26],
                ],
            ],
        ];
    }
}
