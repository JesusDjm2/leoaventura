<?php

namespace Tests\Feature;

use App\Models\ActivityProgress;
use App\Models\Child;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChildReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_parent_can_fetch_aggregated_real_learning_report_for_own_child(): void
    {
        $parent = User::factory()->create();
        $child = Child::create([
            'user_id' => $parent->id,
            'name' => 'Valeria',
            'avatar_key' => 'leo_lion',
            'reading_level' => 'pre-reader',
        ]);

        ActivityProgress::create([
            'child_id' => $child->id,
            'activity_id' => 'act_m_tracing',
            'score' => 100,
            'stars' => 3,
            'metadata' => ['letter' => 'm', 'duration_minutes' => 4],
        ]);
        ActivityProgress::create([
            'child_id' => $child->id,
            'activity_id' => 'act_m_sound_match',
            'score' => 80,
            'stars' => 2,
            'metadata' => ['letter' => 'm', 'duration_minutes' => 3],
        ]);
        ActivityProgress::create([
            'child_id' => $child->id,
            'activity_id' => 'act_enie_tracing',
            'score' => 70,
            'stars' => 2,
            'metadata' => null,
        ]);

        Sanctum::actingAs($parent);

        $response = $this->getJson("/api/children/{$child->id}/report");

        $response->assertOk()
            ->assertJsonPath('child_id', $child->id)
            ->assertJsonPath('child_name', 'Valeria')
            ->assertJsonPath('total_stars', 7)
            ->assertJsonPath('total_sessions', 3)
            ->assertJsonPath('total_practice_minutes', 10);

        $phonemes = collect($response->json('phonemes'))->keyBy('phoneme');
        $this->assertEquals(90, $phonemes['M']['mastery']);
        $this->assertEquals(2, $phonemes['M']['sessions']);
        $this->assertEquals(70, $phonemes['Ñ']['mastery']);
        $this->assertEquals(1, $phonemes['Ñ']['sessions']);
    }

    public function test_other_parent_cannot_access_child_report(): void
    {
        $owner = User::factory()->create();
        $intruder = User::factory()->create();
        $child = Child::create([
            'user_id' => $owner->id,
            'name' => 'Sofía',
            'avatar_key' => 'leo_lion',
            'reading_level' => 'pre-reader',
        ]);

        Sanctum::actingAs($intruder);

        $this->getJson("/api/children/{$child->id}/report")
            ->assertForbidden();
    }

    public function test_unauthenticated_request_to_child_report_is_rejected(): void
    {
        $owner = User::factory()->create();
        $child = Child::create([
            'user_id' => $owner->id,
            'name' => 'Mateo',
            'avatar_key' => 'leo_lion',
            'reading_level' => 'pre-reader',
        ]);

        $this->getJson("/api/children/{$child->id}/report")
            ->assertUnauthorized();
    }
}
