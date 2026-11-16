<?php

namespace Tests\Feature;

use App\Models\Child;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test parent registration returns user data and Sanctum token.
     */
    public function test_parent_can_register_successfully(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'María González',
            'email' => 'maria@example.com',
            'password' => 'Secret1234*',
            'password_confirmation' => 'Secret1234*',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'token',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'maria@example.com',
        ]);
    }

    /**
     * Test login returns Sanctum token and that token is valid in a subsequent request.
     */
    public function test_sanctum_token_is_returned_on_login_and_is_valid_in_subsequent_request(): void
    {
        $user = User::factory()->create([
            'email' => 'padre@example.com',
            'password' => Hash::make('MiPasswordSeguro123'),
        ]);

        // 1. Intento de login exitoso
        $loginResponse = $this->postJson('/api/login', [
            'email' => 'padre@example.com',
            'password' => 'MiPasswordSeguro123',
            'device_name' => 'Tablet Test',
        ]);

        $loginResponse->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'token',
                ],
            ]);

        $token = $loginResponse->json('data.token');
        $this->assertNotEmpty($token);

        // 2. Petición subsiguiente autenticada con el token recibido
        $userResponse = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/user');

        $userResponse->assertStatus(200)
            ->assertJsonPath('data.email', 'padre@example.com');
    }

    /**
     * Test login with invalid credentials returns 401.
     */
    public function test_login_with_invalid_credentials_returns_401(): void
    {
        User::factory()->create([
            'email' => 'padre@example.com',
            'password' => Hash::make('CorrectPassword'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'padre@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('message', 'Credenciales inválidas. Compruebe su correo y contraseña.');
    }

    /**
     * Test parent creates a child profile associated with their account.
     */
    public function test_parent_can_create_child_profile(): void
    {
        $parent = User::factory()->create();
        $token = $parent->createToken('test_token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/children', [
                'name' => 'Mateo',
                'birth_date' => '2022-05-15',
                'avatar_key' => 'leon_leo',
                'reading_level' => 'vocales',
                'accessibility_settings' => [
                    'audio_feedback' => true,
                    'high_contrast' => false,
                ],
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'id',
                    'user_id',
                    'name',
                    'avatar_key',
                    'reading_level',
                ],
            ])
            ->assertJsonPath('data.user_id', $parent->id)
            ->assertJsonPath('data.name', 'Mateo');

        $this->assertDatabaseHas('children', [
            'user_id' => $parent->id,
            'name' => 'Mateo',
        ]);
    }

    /**
     * Test profile isolation: a parent cannot access another parent's child profile and receives 403.
     */
    public function test_parent_cannot_access_another_parents_child_and_receives_403(): void
    {
        // 1. Padre A y su hijo
        $parentA = User::factory()->create(['email' => 'padreA@example.com']);
        $childA = Child::create([
            'user_id' => $parentA->id,
            'name' => 'Lucas',
            'avatar_key' => 'mono_tito',
            'reading_level' => 'vocales',
        ]);

        // 2. Padre B y su token
        $parentB = User::factory()->create(['email' => 'padreB@example.com']);
        $tokenB = $parentB->createToken('token_b')->plainTextToken;

        // 3. Padre B intenta acceder al hijo del Padre A
        $unauthorizedResponse = $this->withHeader('Authorization', "Bearer {$tokenB}")
            ->getJson("/api/children/{$childA->id}");

        $unauthorizedResponse->assertStatus(403);

        // Reset guards for subsequent request in same test
        $this->app['auth']->forgetGuards();

        // 4. Padre A accede a su propio hijo con éxito
        $tokenA = $parentA->createToken('token_a')->plainTextToken;
        $authorizedResponse = $this->withHeader('Authorization', "Bearer {$tokenA}")
            ->getJson("/api/children/{$childA->id}");

        $authorizedResponse->assertStatus(200)
            ->assertJsonPath('data.name', 'Lucas');
    }

    /**
     * Test list of children only returns children belonging to the authenticated parent.
     */
    public function test_children_index_only_lists_authenticated_parents_children(): void
    {
        $parent1 = User::factory()->create();
        $parent2 = User::factory()->create();

        $child1 = Child::create(['user_id' => $parent1->id, 'name' => 'Hijo de Padre 1']);
        $child2 = Child::create(['user_id' => $parent2->id, 'name' => 'Hijo de Padre 2']);

        $token1 = $parent1->createToken('token_1')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token1}")
            ->getJson('/api/children');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $child1->id)
            ->assertJsonPath('data.0.name', 'Hijo de Padre 1');
    }

    /**
     * Test unauthenticated requests to protected child routes receive 401.
     */
    public function test_unauthenticated_requests_receive_401(): void
    {
        $response = $this->getJson('/api/children');
        $response->assertStatus(401);

        $responsePost = $this->postJson('/api/children', ['name' => 'Test']);
        $responsePost->assertStatus(401);
    }

    /**
     * Test validation failure returns 422.
     */
    public function test_validation_errors_return_422(): void
    {
        $parent = User::factory()->create();
        $token = $parent->createToken('token')->plainTextToken;

        // Intentar crear un niño sin el campo requerido 'name'
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/children', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }
}
