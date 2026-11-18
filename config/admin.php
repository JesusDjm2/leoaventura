<?php

$rawPath = trim((string) env('ADMIN_PATH', 'gestion-leo'), '/');

return [
    /*
    |--------------------------------------------------------------------------
    | Ruta privada del Backoffice de Leoaventura
    |--------------------------------------------------------------------------
    | Por seguridad nunca usa `/admin`. Personalizable desde `.env` con ADMIN_PATH.
    */
    'path' => $rawPath !== '' ? $rawPath : 'gestion-leo',
];
