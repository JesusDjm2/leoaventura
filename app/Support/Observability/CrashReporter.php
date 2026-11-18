<?php

namespace App\Support\Observability;

use Illuminate\Support\Str;
use Throwable;

/**
 * Servicio central de Crash Reporting seguro para Laravel.
 *
 * Garantías COPPA:
 * 1. Compuerta de consentimiento: ningún evento se envía si no se aceptaron
 *    los términos de privacidad (`$privacyConsentAccepted === true`).
 * 2. Scrubber obligatorio (`beforeSend`): toda PII se sustituye por `[REDACTED]`
 *    antes de tocar el transporte de red.
 */
final class CrashReporter
{
    public function __construct(
        private readonly CrashReportTransportInterface $transport,
        private readonly PiiScrubber $scrubber = new PiiScrubber(),
        private readonly string $environment = 'local',
        private readonly string $release = 'leo-parvulos@1.0.0',
    ) {}

    /**
     * Captura y reporta una excepción únicamente si existe consentimiento de privacidad.
     *
     * @param  array<string, mixed>  $extra
     * @param  array<string, string>  $tags
     * @return array<string, mixed>|null El evento sanitizado enviado, o null si fue bloqueado por falta de consentimiento.
     */
    public function captureException(
        Throwable $exception,
        bool $privacyConsentAccepted = false,
        array $extra = [],
        array $tags = [],
    ): ?array {
        if (! $privacyConsentAccepted) {
            return null;
        }

        $rawEvent = [
            'event_id' => str_replace('-', '', (string) Str::uuid()),
            'timestamp' => now()->toIso8601String(),
            'platform' => 'php',
            'level' => 'error',
            'environment' => $this->environment,
            'release' => $this->release,
            'message' => $exception->getMessage(),
            'exception' => [
                'values' => [
                    [
                        'type' => $exception::class,
                        'value' => $exception->getMessage(),
                        'file' => basename($exception->getFile()),
                        'line' => $exception->getLine(),
                    ],
                ],
            ],
            'tags' => $tags,
            'extra' => $extra,
        ];

        // Filtro beforeSend obligatorio: elimina toda PII antes del envío
        $cleanEvent = $this->scrubber->scrubEvent($rawEvent);

        $this->transport->send($cleanEvent);

        return $cleanEvent;
    }

    public function transport(): CrashReportTransportInterface
    {
        return $this->transport;
    }
}
