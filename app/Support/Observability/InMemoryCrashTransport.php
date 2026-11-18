<?php

namespace App\Support\Observability;

/**
 * Panel de Sentry en modo test (en memoria) para verificar determinísticamente
 * que únicamente llegan reportes limpios y tras consentimiento explícito.
 */
final class InMemoryCrashTransport implements CrashReportTransportInterface
{
    /** @var array<int, array<string, mixed>> */
    private array $receivedEvents = [];

    public function send(array $payload): bool
    {
        $this->receivedEvents[] = $payload;

        return true;
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public function events(): array
    {
        return $this->receivedEvents;
    }

    public function clear(): void
    {
        $this->receivedEvents = [];
    }
}
