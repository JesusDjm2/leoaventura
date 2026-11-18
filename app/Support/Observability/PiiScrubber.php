<?php

namespace App\Support\Observability;

/**
 * Filtro determinista de eliminación de PII (Personally Identifiable Information)
 * para cumplimiento COPPA antes de enviar cualquier reporte de error a Sentry.
 */
final class PiiScrubber
{
    public const REDACTED = '[REDACTED]';

    /**
     * Claves de arreglos/contextos que siempre deben sustituirse por [REDACTED].
     *
     * @var array<int, string>
     */
    private const SENSITIVE_KEYS = [
        'name',
        'nombre',
        'full_name',
        'first_name',
        'last_name',
        'child_name',
        'parent_name',
        'username',
        'email',
        'correo',
        'password',
        'password_confirmation',
        'token',
        'access_token',
        'refresh_token',
        'authorization',
        'cookie',
        'set-cookie',
        'ip',
        'ip_address',
        'user_ip',
        'device_id',
        'phone',
        'telefono',
        'address',
        'direccion',
        'location',
        'gps',
        'dni',
        'rut',
    ];

    /**
     * Limpia un texto libre sustituyendo emails, nombres etiquetados, tokens,
     * direcciones IP y números telefónicos por `[REDACTED]`.
     */
    public function scrubText(string $text): string
    {
        if ($text === '') {
            return '';
        }

        // 1. Correos electrónicos
        $clean = preg_replace(
            '/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/u',
            self::REDACTED,
            $text
        ) ?? $text;

        // 2. Nombres propios etiquetados (ej. "nombre: Mateo Pérez", "name=Ana López", "niño: Sofía")
        $clean = preg_replace(
            '/\b(nombre|name|niño|niña|child|parent|padre|madre|usuario|user|alumno|student)\s*([:=])\s*([A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]+(?:\s+[A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]+){0,2})/u',
            '$1$2 ' . self::REDACTED,
            $clean
        ) ?? $clean;

        // 3. Nombres propios con formato Nombre Apellido precedidos de preposiciones comunes
        $clean = preg_replace(
            '/\b(para|de|por|for|by|of)\s+([A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]{2,}\s+[A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]{2,})/u',
            '$1 ' . self::REDACTED,
            $clean
        ) ?? $clean;

        // 4. Tokens Bearer y secretos inline (password=..., token=..., dni=...)
        $clean = preg_replace(
            '/\bBearer\s+[A-Za-z0-9\-._~+\/]+=*/i',
            'Bearer ' . self::REDACTED,
            $clean
        ) ?? $clean;

        $clean = preg_replace(
            '/\b(password|passwd|token|secret|api_key|dni|rut|device_id)\s*([:=])\s*\S+/i',
            '$1$2 ' . self::REDACTED,
            $clean
        ) ?? $clean;

        // 5. Direcciones IPv4
        $clean = preg_replace(
            '/\b(?:\d{1,3}\.){3}\d{1,3}\b/',
            self::REDACTED,
            $clean
        ) ?? $clean;

        // 6. Teléfonos (formato internacional o local de >= 8 dígitos)
        $clean = preg_replace(
            '/(?<!\w)(?:\+?\d{1,3}[\s\-]?)?(?:\(?\d{2,4}\)?[\s\-]?)\d{3,4}[\s\-]?\d{3,4}(?!\w)/',
            self::REDACTED,
            $clean
        ) ?? $clean;

        return $clean;
    }

    /**
     * Limpia recursivamente claves sensibles y valores textuales de un arreglo.
     *
     * @param  array<mixed, mixed>  $data
     * @return array<mixed, mixed>
     */
    public function scrubArray(array $data): array
    {
        $sanitized = [];

        foreach ($data as $key => $value) {
            $normalizedKey = is_string($key) ? strtolower(trim($key)) : null;

            if ($normalizedKey !== null && in_array($normalizedKey, self::SENSITIVE_KEYS, true)) {
                $sanitized[$key] = self::REDACTED;
                continue;
            }

            if (is_array($value)) {
                $sanitized[$key] = $this->scrubArray($value);
            } elseif (is_string($value)) {
                $sanitized[$key] = $this->scrubText($value);
            } else {
                $sanitized[$key] = $value;
            }
        }

        return $sanitized;
    }

    /**
     * Ejecuta el filtro `beforeSend` sobre un evento completo compatible con Sentry.
     *
     * @param  array<string, mixed>  $event
     * @return array<string, mixed>
     */
    public function scrubEvent(array $event): array
    {
        // Eliminar bloque de usuario con PII por cumplimiento COPPA estricto
        unset($event['user']);

        return $this->scrubArray($event);
    }
}
