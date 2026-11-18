<?php

namespace Tests\Feature;

use App\Models\ActivityProgress;
use App\Models\Child;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccountSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_parent_can_permanently_delete_account_and_cascade_child_data(): void
    {
        $parent = User::factory()->create([
            'password' => Hash::make('Segura123!'),
        ]);
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
        ]);
        $parent->createToken('mobile_token');

        Sanctum::actingAs($parent);

        // Contraseña incorrecta debe rechazarse con 422
        $this->deleteJson('/api/user', ['password' => 'Incorrecta999'])
            ->assertUnprocessable();

        // Contraseña correcta borra usuario, niños, progreso y tokens
        $this->deleteJson('/api/user', ['password' => 'Segura123!'])
            ->assertOk();

        $this->assertDatabaseMissing('users', ['id' => $parent->id]);
        $this->assertDatabaseMissing('children', ['id' => $child->id]);
        $this->assertDatabaseMissing('activity_progress', ['child_id' => $child->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id' => $parent->id]);
    }

    public function test_forgot_and_reset_password_flow_works_without_leaking_existence(): void
    {
        $parent = User::factory()->create([
            'email' => 'madre@ejemplo.com',
            'password' => Hash::make('Original123!'),
        ]);

        // Correo inexistente recibe la misma respuesta neutra 200
        $this->postJson('/api/forgot-password', ['email' => 'noexiste@ejemplo.com'])
            ->assertOk();

        // Generar token oficial y restablecer contraseña
        $token = Password::broker()->createToken($parent);

        $this->postJson('/api/reset-password', [
            'token' => $token,
            'email' => 'madre@ejemplo.com',
            'password' => 'NuevaSegura456!',
            'password_confirmation' => 'NuevaSegura456!',
        ])->assertOk();

        $parent->refresh();
        $this->assertTrue(Hash::check('NuevaSegura456!', $parent->password));
    }

    public function test_login_endpoint_enforces_rate_limiting(): void
    {
        for ($i = 0; $i < 6; $i++) {
            $this->postJson('/api/login', [
                'email' => 'bloqueo@ejemplo.com',
                'password' => 'malaclave',
            ])->assertUnauthorized();
        }

        // El 7.º intento en el mismo minuto recibe 429 Too Many Requests
        $this->postJson('/api/login', [
            'email' => 'bloqueo@ejemplo.com',
            'password' => 'malaclave',
        ])->assertStatus(429);
    }
}
