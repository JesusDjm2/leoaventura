<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Crea o actualiza de forma idempotente la cuenta administradora local.
     */
    public function run(): void
    {
        $email = (string) env('ADMIN_DEFAULT_EMAIL', 'admin@leoaventura.app');
        $password = (string) env('ADMIN_DEFAULT_PASSWORD', 'LeoAdmin2026!');

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => 'Administrador Leoaventura',
                'password' => Hash::make($password),
                'is_admin' => true,
                'plan_tier' => User::PLAN_PREMIUM,
                'subscription_status' => 'active',
            ]
        );
    }
}
