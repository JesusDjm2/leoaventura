<?php

namespace Tests\Feature;

use App\Models\ActivityProgress;
use App\Models\Child;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SyncProgressTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test sending a batch of 5 progress events inserts all of them correctly into the database.
     */
    public function test_batch_of_five_progress_events_are_inserted_correctly(): void
    {
        $parent = User::factory()->create();
        $child = Child::create([
            'user_id' => $parent->id,
            'name' => 'Mateo',
            'avatar_key' => 'leon_leo',
            'reading_level' => 'vocales',
        ]);

        $token = $parent->createToken('device_token')->plainTextToken;

        $now = Carbon::now();
        $events = [];
        for ($i = 1; $i <= 5; $i++) {
            $events[] = [
                'child_id' => $child->id,
                'activity_id' => "VOCAL_A_ACT_{$i}",
                'score' => $i * 20,
                'stars' => min($i, 3),
                'metadata' => ['attempt' => 1, 'device' => 'Tablet Android'],
                'updated_at' => $now->copy()->subMinutes(10 - $i)->toISOString(),
                'deleted_at' => null,
            ];
        }

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => $events,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('summary.total_events', 5)
            ->assertJsonPath('summary.inserted', 5)
            ->assertJsonPath('summary.updated', 0)
            ->assertJsonPath('summary.deleted', 0);

        $this->assertDatabaseCount('activity_progress', 5);

        for ($i = 1; $i <= 5; $i++) {
            $this->assertDatabaseHas('activity_progress', [
                'child_id' => $child->id,
                'activity_id' => "VOCAL_A_ACT_{$i}",
                'score' => $i * 20,
                'deleted_at' => null,
            ]);
        }
    }

    /**
     * Test conflict resolution Last-Write-Wins: sending two events for the same activity
     * with different updated_at timestamps persists only the most recent event.
     */
    public function test_last_write_wins_persists_only_the_most_recent_event(): void
    {
        $parent = User::factory()->create();
        $child = Child::create([
            'user_id' => $parent->id,
            'name' => 'Sofía',
            'avatar_key' => 'jirafa_ji',
            'reading_level' => 'vocales',
        ]);

        $token = $parent->createToken('device_token')->plainTextToken;

        // 1. Primer envío: estado anterior (hace 1 hora con score 50)
        $olderTimestamp = Carbon::now()->subHour()->toISOString();
        $firstBatchResponse = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $child->id,
                        'activity_id' => 'FONEMA_M_PRACTICA',
                        'score' => 50,
                        'stars' => 1,
                        'updated_at' => $olderTimestamp,
                        'deleted_at' => null,
                    ],
                ],
            ]);

        $firstBatchResponse->assertStatus(200)
            ->assertJsonPath('summary.inserted', 1);

        $this->assertDatabaseHas('activity_progress', [
            'child_id' => $child->id,
            'activity_id' => 'FONEMA_M_PRACTICA',
            'score' => 50,
        ]);

        // 2. Segundo envío: estado más reciente (hace 5 minutos con score 100)
        $newerTimestamp = Carbon::now()->subMinutes(5)->toISOString();
        $secondBatchResponse = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $child->id,
                        'activity_id' => 'FONEMA_M_PRACTICA',
                        'score' => 100,
                        'stars' => 3,
                        'updated_at' => $newerTimestamp,
                        'deleted_at' => null,
                    ],
                ],
            ]);

        $secondBatchResponse->assertStatus(200)
            ->assertJsonPath('summary.updated', 1)
            ->assertJsonPath('summary.ignored', 0);

        // Debe persistir el score 100 y no el 50
        $this->assertDatabaseCount('activity_progress', 1);
        $this->assertDatabaseHas('activity_progress', [
            'child_id' => $child->id,
            'activity_id' => 'FONEMA_M_PRACTICA',
            'score' => 100,
            'stars' => 3,
        ]);

        // 3. Tercer envío: un evento desfasado con fecha antigua (hace 2 horas con score 20)
        $outdatedTimestamp = Carbon::now()->subHours(2)->toISOString();
        $thirdBatchResponse = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $child->id,
                        'activity_id' => 'FONEMA_M_PRACTICA',
                        'score' => 20,
                        'stars' => 0,
                        'updated_at' => $outdatedTimestamp,
                        'deleted_at' => null,
                    ],
                ],
            ]);

        $thirdBatchResponse->assertStatus(200)
            ->assertJsonPath('summary.updated', 0)
            ->assertJsonPath('summary.ignored', 1);

        // Continúa persistiendo el score más reciente (100)
        $this->assertDatabaseHas('activity_progress', [
            'child_id' => $child->id,
            'activity_id' => 'FONEMA_M_PRACTICA',
            'score' => 100,
        ]);
    }

    /**
     * Test sending an event with deleted_at marks the record as soft deleted instead of physically deleting it.
     */
    public function test_event_with_deleted_at_soft_deletes_record_instead_of_physical_deletion(): void
    {
        $parent = User::factory()->create();
        $child = Child::create([
            'user_id' => $parent->id,
            'name' => 'Lucas',
            'avatar_key' => 'mono_tito',
            'reading_level' => 'vocales',
        ]);

        $token = $parent->createToken('device_token')->plainTextToken;

        $deletionTime = Carbon::now()->toISOString();

        // Enviar evento con deleted_at
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $child->id,
                        'activity_id' => 'VOCAL_E_ELIMINAR',
                        'score' => 80,
                        'stars' => 2,
                        'updated_at' => $deletionTime,
                        'deleted_at' => $deletionTime,
                    ],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('summary.deleted', 1);

        // El registro no debe aparecer en consultas regulares de Eloquent
        $this->assertNull(ActivityProgress::where('activity_id', 'VOCAL_E_ELIMINAR')->first());

        // Pero SÍ debe existir en la base de datos físicamente con deleted_at no nulo (Soft Delete)
        $this->assertSoftDeleted('activity_progress', [
            'child_id' => $child->id,
            'activity_id' => 'VOCAL_E_ELIMINAR',
            'score' => 80,
        ]);

        $this->assertDatabaseCount('activity_progress', 1);
    }

    /**
     * Test multi-tenant isolation: syncing for another parent's child returns 403 and rolls back.
     */
    public function test_cannot_sync_for_another_parents_child_and_receives_403(): void
    {
        $parentA = User::factory()->create();
        $childA = Child::create(['user_id' => $parentA->id, 'name' => 'Hijo A']);

        $parentB = User::factory()->create();
        $tokenB = $parentB->createToken('token_b')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$tokenB}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $childA->id,
                        'activity_id' => 'VOCAL_O_TEST',
                        'score' => 90,
                        'updated_at' => Carbon::now()->toISOString(),
                        'deleted_at' => null,
                    ],
                ],
            ]);

        $response->assertStatus(403);
        $this->assertDatabaseCount('activity_progress', 0);
    }

    /**
     * Test GET /api/progress returns the authenticated parent's synced progress (multi-device read).
     */
    public function test_get_progress_returns_synced_state_for_authenticated_parent_only(): void
    {
        $parent = User::factory()->create();
        $child = Child::create(['user_id' => $parent->id, 'name' => 'Sofía']);
        $token = $parent->createToken('web_token')->plainTextToken;

        // Otro padre con progreso distinto (no debe filtrarse)
        $otherParent = User::factory()->create();
        $otherChild = Child::create(['user_id' => $otherParent->id, 'name' => 'Lucas']);
        ActivityProgress::create([
            'child_id' => $otherChild->id,
            'activity_id' => 'act_other',
            'score' => 50,
            'stars' => 1,
        ]);

        // Guardar progreso desde "la web"
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/sync/progress', [
                'events' => [
                    [
                        'child_id' => $child->id,
                        'activity_id' => 'act_m_tracing',
                        'score' => 100,
                        'stars' => 3,
                        'updated_at' => Carbon::now()->toISOString(),
                        'deleted_at' => null,
                    ],
                ],
            ])->assertOk();

        // Consultar desde "el móvil" con GET /api/progress
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/progress');

        $response->assertOk()
            ->assertJsonPath('total_completed', 1)
            ->assertJsonPath('total_stars', 3)
            ->assertJsonCount(1, 'progress')
            ->assertJsonPath('progress.0.child_id', $child->id)
            ->assertJsonPath('progress.0.child_name', 'Sofía')
            ->assertJsonPath('progress.0.activity_id', 'act_m_tracing')
            ->assertJsonPath('progress.0.score', 100)
            ->assertJsonPath('progress.0.stars', 3);
    }
}
