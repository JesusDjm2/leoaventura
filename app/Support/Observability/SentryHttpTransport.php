<?php

namespace App\Support\Observability;

use Illuminate\Support\Facades\Http;

/**
 * Transporte HTTP compatible con la API Store v7 de Sentry.
 * Solo envía eventos ya pasados por PiiScrubber cuando existe un DSN válido.
 */
final class SentryHttpTransport implements CrashReportTransportInterface
{
    public function __construct(
        private readonly ?string $dsn,
    ) {}

    public function send(array $payload): bool
    {
        if (empty($this->dsn)) {
            return false;
        }

        $parsed = parse_url($this->dsn);
        if (! is_array($parsed) || empty($parsed['host']) || empty($parsed['user']) || empty($parsed['path'])) {
            return false;
        }

        $scheme = $parsed['scheme'] ?? 'https';
        $host = $parsed['host'];
        $port = isset($parsed['port']) ? ':' . $parsed['port'] : '';
        $publicKey = $parsed['user'];
        $projectId = trim($parsed['path'], '/');

        if ($projectId === '') {
            return false;
        }

        $endpoint = "{$scheme}://{$host}{$port}/api/{$projectId}/store/";
        $authHeader = sprintf(
            'Sentry sentry_version=7, sentry_client=leoparvulos-php/1.0, sentry_key=%s',
            $publicKey
        );

        try {
            $response = Http::timeout(3)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                    'X-Sentry-Auth' => $authHeader,
                ])
                ->post($endpoint, $payload);

            return $response->successful();
        } catch (\Throwable) {
            // Nunca dejar que un fallo de telemetría interrumpa el flujo de la app
            return false;
        }
    }
}
