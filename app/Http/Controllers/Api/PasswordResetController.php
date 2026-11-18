<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Symfony\Component\HttpFoundation\Response;

class PasswordResetController extends Controller
{
    /**
     * Envía enlace de recuperación de contraseña sin revelar si el correo existe
     * (prevención de enumeración de cuentas).
     */
    public function sendResetLink(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
        ]);

        Password::sendResetLink(['email' => $validated['email']]);

        return response()->json([
            'message' => 'Si el correo está registrado, enviaremos instrucciones para restablecer la contraseña.',
        ], Response::HTTP_OK);
    }

    /**
     * Restablece la contraseña con token válido y revoca todos los tokens Sanctum previos.
     */
    public function reset(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);

        $status = Password::reset(
            $validated,
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();

                // Revocar sesiones activas previas por seguridad
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'message' => 'El token de recuperación es inválido o ha expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Contraseña restablecida exitosamente.',
        ], Response::HTTP_OK);
    }
}
