<?php

namespace App\Providers;

use App\Support\Observability\CrashReporter;
use App\Support\Observability\CrashReportTransportInterface;
use App\Support\Observability\InMemoryCrashTransport;
use App\Support\Observability\PiiScrubber;
use App\Support\Observability\SentryHttpTransport;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PiiScrubber::class, static fn (): PiiScrubber => new PiiScrubber());

        $this->app->singleton(CrashReportTransportInterface::class, static function (): CrashReportTransportInterface {
            $driver = (string) config('observability.driver', 'sentry');
            if ($driver === 'memory') {
                return new InMemoryCrashTransport();
            }

            return new SentryHttpTransport(config('observability.dsn'));
        });

        $this->app->singleton(CrashReporter::class, static function ($app): CrashReporter {
            return new CrashReporter(
                transport: $app->make(CrashReportTransportInterface::class),
                scrubber: $app->make(PiiScrubber::class),
                environment: (string) config('observability.environment', 'local'),
                release: (string) config('observability.release', 'leo-parvulos@1.0.0'),
            );
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
