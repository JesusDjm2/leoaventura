<?php

use App\Http\Controllers\Admin\AdminAudioController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminCurriculumController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminSubscriberController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome', [
        'appWebUrl' => env('APP_WEB_URL', 'http://localhost:8080'),
    ]);
})->name('portal.home');

// Panel de Administración privado (sin enlaces públicos; ruta configurable vía ADMIN_PATH en .env)
Route::prefix((string) config('admin.path', 'admin'))->name('admin.')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('login.submit');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
        Route::get('/', [AdminDashboardController::class, 'index'])->name('dashboard');

        Route::get('/subscribers', [AdminSubscriberController::class, 'index'])->name('subscribers.index');
        Route::patch('/subscribers/{user}/plan', [AdminSubscriberController::class, 'updatePlan'])->name('subscribers.plan');

        Route::get('/curriculum', [AdminCurriculumController::class, 'index'])->name('curriculum.index');
        Route::post('/curriculum', [AdminCurriculumController::class, 'store'])->name('curriculum.store');
        Route::patch('/curriculum/{level}/toggle', [AdminCurriculumController::class, 'toggle'])->name('curriculum.toggle');
        Route::put('/curriculum/{level}', [AdminCurriculumController::class, 'update'])->name('curriculum.update');

        Route::get('/audio', [AdminAudioController::class, 'index'])->name('audio.index');
        Route::post('/audio/upload', [AdminAudioController::class, 'upload'])->name('audio.upload');
        Route::delete('/audio/{category}/{clipName}', [AdminAudioController::class, 'destroy'])->name('audio.destroy');
    });
});
