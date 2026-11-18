<?php

use App\Http\Controllers\Api\AudioController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChildController;
use App\Http\Controllers\Api\CurriculumController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SyncController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - LeoPárvulos
|--------------------------------------------------------------------------
*/

// Rutas públicas de autenticación para padres y educadores (con límite contra fuerza bruta)
Route::middleware('throttle:6,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])->name('api.register');
    Route::post('/login', [AuthController::class, 'login'])->name('api.login');
    Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLink'])->name('api.password.forgot');
    Route::post('/reset-password', [PasswordResetController::class, 'reset'])->name('api.password.reset');
});

// Currículo dinámico de fonemas y actividades (público, sin PII, cacheable offline-first)
Route::get('/curriculum/levels', [CurriculumController::class, 'levels'])->name('api.curriculum.levels');

// Catálogo de audio (público: no contiene datos personales y la app lo
// necesita antes del login para precargar instrucciones y fonemas).
Route::get('/audio/manifest', [AudioController::class, 'manifest'])->name('api.audio.manifest');
Route::get('/audio/v{version}/{category}/{file}', [AudioController::class, 'clip'])
    ->whereNumber('version')
    ->where(['category' => '[a-z]+', 'file' => '[a-z0-9_]+\.[a-z0-9]+'])
    ->name('api.audio.clip');

// Rutas protegidas mediante tokens de Laravel Sanctum
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('api.logout');
    Route::get('/user', [AuthController::class, 'me'])->name('api.user');
    Route::delete('/user', [AuthController::class, 'destroy'])->name('api.user.destroy');

    // Perfiles de niños (colección)
    Route::get('/children', [ChildController::class, 'index'])->name('api.children.index');
    Route::post('/children', [ChildController::class, 'store'])->name('api.children.store');

    // Sincronización offline-first y consulta de progreso de actividades
    Route::get('/progress', [SyncController::class, 'index'])->name('api.progress.index');
    Route::post('/sync/progress', [SyncController::class, 'syncProgress'])->name('api.sync.progress');

    // Perfiles individuales de niños protegidos por middleware de aislamiento de propietario
    Route::middleware('child.owner')->group(function () {
        Route::get('/children/{child}', [ChildController::class, 'show'])->name('api.children.show');
        Route::get('/children/{child}/report', [ReportController::class, 'show'])->name('api.children.report');
        Route::put('/children/{child}', [ChildController::class, 'update'])->name('api.children.update');
        Route::delete('/children/{child}', [ChildController::class, 'destroy'])->name('api.children.destroy');
    });
});
