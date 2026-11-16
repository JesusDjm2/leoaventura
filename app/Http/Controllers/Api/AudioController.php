<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\Audio\AudioManifestBuilder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class AudioController extends Controller
{
    /**
     * GET /api/audio/manifest
     *
     * Caché: `public, max-age=300, must-revalidate` + ETag = manifest_hash.
     * Con If-None-Match coincidente responde 304 sin cuerpo.
     */
    public function manifest(Request $request): Response|JsonResponse
    {
        $version = (int) config('audio.version');
        $path = AudioManifestBuilder::fromConfig()->manifestPath($version);

        if (! is_file($path)) {
            return response()->json([
                'message' => 'El manifiesto de audio no está generado. Ejecuta `php artisan audio:manifest`.',
            ], 503)->header('Cache-Control', 'no-store');
        }

        $body = file_get_contents($path);
        $hash = json_decode($body, true)['manifest_hash'] ?? hash('sha256', $body);

        $response = new Response($body, 200, ['Content-Type' => 'application/json']);
        $response->setEtag($hash);
        $response->headers->set(
            'Cache-Control',
            'public, max-age='.(int) config('audio.manifest_max_age').', must-revalidate',
        );
        $response->isNotModified($request); // convierte a 304 si el ETag coincide

        return $response;
    }

    /**
     * GET /api/audio/v{version}/{category}/{file}?sha256=<hash>
     *
     * Si el cliente pide el clip con el hash vigente se sirve como inmutable
     * (1 año); sin hash o con uno viejo, con la misma caché corta del manifiesto.
     */
    public function clip(Request $request, int $version, string $category, string $file): BinaryFileResponse
    {
        $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
        $name = pathinfo($file, PATHINFO_FILENAME);
        $mimes = config('audio.mime_types');

        abort_unless(
            $version === (int) config('audio.version')
            && in_array($category, config('audio.categories'), true)
            && isset($mimes[$ext])
            && preg_match(AudioManifestBuilder::NAME_PATTERN, $name),
            404,
        );

        $path = AudioManifestBuilder::fromConfig()->versionDir($version)
            .DIRECTORY_SEPARATOR.$category.DIRECTORY_SEPARATOR.$name.'.'.$ext;
        abort_unless(is_file($path), 404);

        $sha = hash_file('sha256', $path);
        $cache = $request->query('sha256') === $sha
            ? 'public, max-age='.(int) config('audio.clip_max_age').', immutable'
            : 'public, max-age='.(int) config('audio.manifest_max_age').', must-revalidate';

        return response()->file($path, [
            'Content-Type' => $mimes[$ext],
            'Cache-Control' => $cache,
            'ETag' => '"'.$sha.'"',
        ]);
    }
}
