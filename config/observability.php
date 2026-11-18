<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Observabilidad y Crash Reporting Seguro (COPPA / Zero PII)
    |--------------------------------------------------------------------------
    |
    | Driver soportado: 'sentry' (envío HTTP a DSN), 'memory' (panel de test),
    | o 'null' (desactivado). Por cumplimiento COPPA, send_default_pii es
    | siempre false y requiere consentimiento de privacidad explícito.
    |
    */
    'driver' => env('CRASH_REPORTING_DRIVER', env('APP_ENV') === 'testing' ? 'memory' : 'sentry'),

    'dsn' => env('SENTRY_DSN'),

    'environment' => env('APP_ENV', 'local'),

    'release' => env('APP_RELEASE', 'leo-parvulos@1.0.0'),

    'send_default_pii' => false,

    'require_privacy_consent' => true,
];
