<?php

namespace Tests\Feature;

use App\Models\ActivityProgress;
use App\Models\Child;
use App\Models\CurriculumLevel;
use App\Models\User;
use Database\Seeders\CurriculumSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_landing_never_exposes_admin_and_obvious_admin_route_returns_404(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('Comenzar a Jugar')
            ->assertDontSee('Panel Administrador')
            ->assertDontSee('gestion-leo')
            ->assertDontSee('/admin');

        // La ruta obvia /admin no existe (404)
        $this->get('/admin')->assertNotFound();

        // Invitado en /gestion-leo redirige limpiamente al login (nunca 500 RouteNotFound)
        $this->get('/gestion-leo')
            ->assertRedirect(route('admin.login'));

        $this->get('/gestion-leo/login')
            ->assertOk()
            ->assertSee('noindex, nofollow', false)
            ->assertSee('Iniciar sesión');
    }

    public function test_non_admin_user_cannot_access_admin_dashboard(): void
    {
        $parent = User::factory()->create(['is_admin' => false]);

        $this->actingAs($parent)
            ->get('/gestion-leo')
            ->assertForbidden();
    }

    public function test_admin_can_login_and_view_dashboard_kpis(): void
    {
        $admin = User::factory()->create([
            'email' => 'admin@leoaventura.app',
            'password' => Hash::make('LeoAdmin2026!'),
            'is_admin' => true,
        ]);

        $family = User::factory()->create(['plan_tier' => User::PLAN_FREE]);
        $child = Child::create([
            'user_id' => $family->id,
            'name' => 'Valeria',
            'avatar_key' => 'leo_lion',
            'reading_level' => 'pre-reader',
        ]);
        ActivityProgress::create([
            'child_id' => $child->id,
            'activity_id' => 'act_m_tracing',
            'score' => 100,
            'stars' => 3,
        ]);

        $this->post('/gestion-leo/login', [
            'email' => $admin->email,
            'password' => 'LeoAdmin2026!',
        ])->assertRedirect('/gestion-leo');

        $this->get('/gestion-leo')
            ->assertOk()
            ->assertSee('Dashboard General')
            ->assertSee('Valeria')
            ->assertSee('act_m_tracing');
    }

    public function test_admin_can_upgrade_family_from_free_to_premium(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $family = User::factory()->create([
            'name' => 'Familia Demo',
            'plan_tier' => User::PLAN_FREE,
            'subscription_status' => 'active',
        ]);

        $this->actingAs($admin)
            ->patch("/gestion-leo/subscribers/{$family->id}/plan", [
                'plan_tier' => 'premium',
                'subscription_status' => 'active',
            ])
            ->assertRedirect();

        $family->refresh();
        $this->assertEquals('premium', $family->plan_tier);
        $this->assertTrue($family->isPremium());
        $this->assertNotNull($family->subscription_expires_at);
    }

    public function test_admin_can_publish_new_phoneme_and_toggle_level_live(): void
    {
        $this->seed(CurriculumSeeder::class);
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)
            ->post('/gestion-leo/curriculum', [
                'letter' => 'z',
                'phoneme' => '/s/',
                'example_word' => 'Zorro',
                'emoji' => '🦊',
                'unit' => 4,
            ])
            ->assertRedirect();

        $levelZ = CurriculumLevel::where('code', 'phoneme_z')->first();
        $this->assertNotNull($levelZ);
        $this->assertTrue($levelZ->is_active);
        $this->assertEquals(2, $levelZ->activities()->count());

        $this->getJson('/api/curriculum/levels')
            ->assertOk()
            ->assertJsonFragment(['letter' => 'z', 'example_word' => 'Zorro']);

        $this->actingAs($admin)
            ->patch("/gestion-leo/curriculum/{$levelZ->id}/toggle")
            ->assertRedirect();

        $this->assertFalse($levelZ->fresh()->is_active);
    }
}
