<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'child.owner' => \App\Http\Middleware\EnsureChildBelongsToParent::class,
            'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
        ]);

        $middleware->redirectGuestsTo(static function (\Illuminate\Http\Request $request): ?string {
            if ($request->expectsJson() || $request->is('api/*')) {
                return null;
            }

            return route('admin.login');
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->reportable(function (\Throwable $e): void {
            $request = request();
            $hasConsent = $request !== null
                && strtolower((string) $request->header('X-Privacy-Consent')) === 'accepted';

            if (! $hasConsent) {
                return;
            }

            app(\App\Support\Observability\CrashReporter::class)->captureException(
                exception: $e,
                privacyConsentAccepted: true,
                extra: [
                    'path' => $request->path(),
                    'method' => $request->method(),
                ],
                tags: ['layer' => 'backend'],
            );
        });
    })->create();
