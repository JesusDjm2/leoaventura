<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Raíz del catálogo de audio
    |--------------------------------------------------------------------------
    |
    | Contiene una carpeta por versión del catálogo (v1, v2, ...) con las
    | subcarpetas de categoría. Los clips se generan con
    | scripts/normalize_audio.sh y el manifiesto con `php artisan audio:manifest`.
    | Ver docs/audio/PIPELINE.md.
    |
    */

    'root' => env('AUDIO_ROOT', base_path('assets/audio')),

    // Ruta opcional al cliente Flutter para mantener sincronizado el bundle local al grabar.
    'flutter_bundle_root' => env('AUDIO_FLUTTER_BUNDLE_ROOT', base_path('client/assets/audio')),

    // Binario de ffmpeg (opcional: si es nulo se autodetecta en PATH o imageio-ffmpeg).
    'ffmpeg_binary' => env('FFMPEG_BINARY'),

    // Versión del catálogo que sirve la API.
    'version' => (int) env('AUDIO_VERSION', 1),

    'categories' => ['fonemas', 'palabras', 'silabas', 'instrucciones', 'mascota'],

    // Prefijo obligatorio del nombre de archivo según la categoría.
    'prefixes' => [
        'fonemas' => 'fonema',
        'palabras' => 'palabra',
        'silabas' => 'silaba',
        'instrucciones' => 'instruccion',
        'mascota' => 'mascota',
    ],

    // Formato lógico => extensión. Cada clip debe existir en todos los formatos.
    'formats' => [
        'opus' => 'opus',
        'aac' => 'm4a',
    ],

    'mime_types' => [
        'opus' => 'audio/ogg',
        'm4a' => 'audio/mp4',
    ],

    /*
    |--------------------------------------------------------------------------
    | Caché HTTP
    |--------------------------------------------------------------------------
    |
    | El manifiesto es un puntero mutable: caché corta + revalidación por ETag
    | (= manifest_hash). Los clips pedidos con ?sha256=<hash> son contenido
    | direccionado por hash y se cachean como inmutables.
    |
    */

    'manifest_max_age' => (int) env('AUDIO_MANIFEST_MAX_AGE', 300),

    'clip_max_age' => 31536000,

];
