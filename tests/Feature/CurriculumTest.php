<?php

namespace Tests\Feature;

use App\Models\CurriculumActivity;
use App\Models\CurriculumLevel;
use Database\Seeders\CurriculumSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CurriculumTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_inserts_20_phonemes_and_40_dynamic_activities_idempotently(): void
    {
        $this->seed(CurriculumSeeder::class);

        $this->assertDatabaseCount('curriculum_levels', 20);
        $this->assertDatabaseCount('curriculum_activities', 40);

        $this->assertSame(20, CurriculumActivity::where('type', CurriculumActivity::TYPE_TRACING)->count());
        $this->assertSame(20, CurriculumActivity::where('type', CurriculumActivity::TYPE_SOUND_MATCH)->count());

        // Verificar idempotencia ejecutando el seeder una segunda vez
        $this->seed(CurriculumSeeder::class);
        $this->assertDatabaseCount('curriculum_levels', 20);
        $this->assertDatabaseCount('curriculum_activities', 40);
    }

    public function test_curriculum_levels_endpoint_returns_20_phonemes_with_activities(): void
    {
        $this->seed(CurriculumSeeder::class);

        $response = $this->getJson('/api/curriculum/levels');

        $response->assertOk()
            ->assertJsonPath('version', '1.0')
            ->assertJsonPath('total_phonemes', 20)
            ->assertJsonCount(20, 'levels')
            ->assertJsonStructure([
                'version',
                'total_phonemes',
                'levels' => [
                    '*' => [
                        'id',
                        'code',
                        'title',
                        'phoneme',
                        'letter',
                        'example_word',
                        'unit',
                        'order_index',
                        'audio_key',
                        'activities' => [
                            '*' => [
                                'id',
                                'activity_code',
                                'type',
                                'title',
                                'instruction',
                                'audio_key',
                                'order_index',
                                'payload',
                            ],
                        ],
                    ],
                ],
            ]);

        // Verificar que existe el fonema /s/ con ambas actividades (trazado y emparejamiento)
        $levels = collect($response->json('levels'));
        $levelS = $levels->firstWhere('letter', 's');

        $this->assertNotNull($levelS);
        $this->assertSame('/s/', $levelS['phoneme']);
        $this->assertSame('Sol', $levelS['example_word']);
        $this->assertCount(2, $levelS['activities']);

        $types = collect($levelS['activities'])->pluck('type')->all();
        $this->assertEquals(['tracing', 'sound_match'], $types);

        $tracingActivity = $levelS['activities'][0];
        $this->assertSame('s', $tracingActivity['payload']['letter']);
        $this->assertSame('fonemas/fonema_s', $tracingActivity['payload']['audio_key']);
        $this->assertNotEmpty($tracingActivity['payload']['checkpoints']);
    }

    public function test_inactive_levels_are_excluded_from_curriculum_endpoint(): void
    {
        $this->seed(CurriculumSeeder::class);

        CurriculumLevel::where('letter', 'ñ')->update(['is_active' => false]);

        $response = $this->getJson('/api/curriculum/levels');

        $response->assertOk()
            ->assertJsonPath('total_phonemes', 19)
            ->assertJsonCount(19, 'levels');
    }
}
