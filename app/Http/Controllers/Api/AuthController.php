<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    /**
     * Register a new parent user and return access token.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken($request->device_name ?? 'parent_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado exitosamente.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'created_at' => $user->created_at,
                ],
                'token' => $token,
            ],
        ], Response::HTTP_CREATED);
    }

    /**
     * Authenticate parent and return access token.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Credenciales inválidas. Compruebe su correo y contraseña.',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $tokenName = $request->device_name ?? 'parent_token';
        $token = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'message' => 'Inicio de sesión exitoso.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                ],
                'token' => $token,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * Log the parent user out by revoking the current token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente.',
        ], Response::HTTP_OK);
    }

    /**
     * Get the authenticated parent user profile.
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $request->user(),
        ], Response::HTTP_OK);
    }
}
