<?php

namespace App\Support\Observability;

interface CrashReportTransportInterface
{
    /**
     * Envía un evento de crash ya sanitizado (sin PII) al destino configurado.
     *
     * @param  array<string, mixed>  $payload
     */
    public function send(array $payload): bool;
}
