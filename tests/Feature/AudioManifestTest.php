<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\File;
use Tests\TestCase;

class AudioManifestTest extends TestCase
{
    private string $root;

    /** Clips del catálogo de prueba: id => contenido base. */
    private const CLIPS = [
        'fonemas/fonema_m',
        'fonemas/fonema_s',
        'fonemas/fonema_a',
        'instrucciones/instruccion_traza_letra',
    ];

    protected function setUp(): void
    {
        parent::setUp();
        $this->root = sys_get_temp_dir().DIRECTORY_SEPARATOR.'leo_audio_'.bin2hex(random_bytes(6));
        config(['audio.root' => $this->root, 'audio.version' => 1]);

        foreach (self::CLIPS as $id) {
            foreach (['opus', 'm4a'] as $ext) {
                $this->putClip("{$id}.{$ext}", "{$id}.{$ext}:".random_bytes(64));
            }
        }
        File::put($this->root.'/v1/fonemas/.gitkeep', '');
    }

    protected function tearDown(): void
    {
        File::deleteDirectory($this->root);
        parent::tearDown();
    }

    private function putClip(string $relative, string $bytes): void
    {
        $path = $this->root.'/v1/'.$relative;
        File::ensureDirectoryExists(dirname($path));
        File::put($path, $bytes);
    }

    private function manifestFromDisk(): array
    {
        return json_decode(File::get($this->root.'/v1/manifest.json'), true);
    }

    public function test_command_generates_manifest_with_unique_sha256_per_clip(): void
    {
        $this->artisan('audio:manifest')->assertSuccessful();

        $manifest = $this->manifestFromDisk();
        $this->assertSame(1, $manifest['version']);
        $this->assertSame(4, $manifest['clip_count']);
        $this->assertGreaterThanOrEqual(3, count($manifest['clips']));
        $this->assertSame(
            ['fonemas/fonema_a', 'fonemas/fonema_m', 'fonemas/fonema_s', 'instrucciones/instruccion_traza_letra'],
            array_keys($manifest['clips']),
        );

        $hashes = [];
        foreach ($manifest['clips'] as $id => $clip) {
            $this->assertSame(['aac', 'opus'], array_keys($clip['files']));
            foreach ($clip['files'] as $file) {
                $full = $this->root.'/v1/'.$file['path'];
                $this->assertMatchesRegularExpression('/^[0-9a-f]{64}$/', $file['sha256']);
                $this->assertSame(hash_file('sha256', $full), $file['sha256']);
                $this->assertSame(filesize($full), $file['bytes']);
                $hashes[] = $file['sha256'];
            }
        }
        $this->assertCount(8, $hashes);
        $this->assertCount(8, array_unique($hashes), 'los hashes deben ser únicos');
        $this->assertMatchesRegularExpression('/^[0-9a-f]{64}$/', $manifest['manifest_hash']);
    }

    public function test_manifest_is_deterministic_and_hash_changes_when_a_clip_changes(): void
    {
        $this->artisan('audio:manifest')->assertSuccessful();
        $first = File::get($this->root.'/v1/manifest.json');

        $this->artisan('audio:manifest')->assertSuccessful();
        $this->assertSame($first, File::get($this->root.'/v1/manifest.json'));

        $this->putClip('fonemas/fonema_m.opus', 'regrabado '.random_bytes(32));
        $this->artisan('audio:manifest')->assertSuccessful();
        $second = $this->manifestFromDisk();

        $this->assertNotSame(json_decode($first, true)['manifest_hash'], $second['manifest_hash']);
    }

    public function test_command_rejects_catalog_that_breaks_the_naming_convention(): void
    {
        $this->putClip('fonemas/Fonema_Ñ.opus', 'x');
        $this->artisan('audio:manifest')->assertFailed();
    }

    public function test_command_rejects_clip_missing_a_format(): void
    {
        $this->putClip('mascota/mascota_saludo.opus', 'solo opus');
        $this->artisan('audio:manifest')->assertFailed();
        $this->assertFileDoesNotExist($this->root.'/v1/manifest.json');
    }

    public function test_strict_mode_fails_on_duplicate_audio(): void
    {
        $this->putClip('palabras/palabra_mama.opus', File::get($this->root.'/v1/fonemas/fonema_m.opus'));
        $this->putClip('palabras/palabra_mama.m4a', 'otro');

        $this->artisan('audio:manifest')->assertSuccessful();
        $this->artisan('audio:manifest --strict')->assertFailed();
    }

    public function test_endpoint_serves_manifest_with_cache_control_and_etag(): void
    {
        $this->artisan('audio:manifest')->assertSuccessful();
        $manifest = $this->manifestFromDisk();

        $response = $this->getJson('/api/audio/manifest');

        $response->assertOk()
            ->assertHeader('Content-Type', 'application/json')
            ->assertJsonPath('version', 1)
            ->assertJsonPath('manifest_hash', $manifest['manifest_hash'])
            ->assertJsonCount(4, 'clips');
        $this->assertSame($manifest, $response->json());

        $cacheControl = $response->headers->get('Cache-Control');
        $directives = array_map('trim', explode(',', $cacheControl));
        sort($directives);
        $this->assertSame(['max-age=300', 'must-revalidate', 'public'], $directives);
        $this->assertSame('"'.$manifest['manifest_hash'].'"', $response->headers->get('ETag'));

        // Revalidación: mismo ETag => 304 sin cuerpo.
        $this->get('/api/audio/manifest', ['If-None-Match' => '"'.$manifest['manifest_hash'].'"'])
            ->assertStatus(304)
            ->assertContent('');
    }

    public function test_endpoint_returns_503_when_manifest_was_not_generated(): void
    {
        $this->getJson('/api/audio/manifest')
            ->assertStatus(503)
            ->assertHeader('Cache-Control', 'no-store, private');
    }

    public function test_clip_endpoint_serves_audio_immutable_when_hash_matches(): void
    {
        $this->artisan('audio:manifest')->assertSuccessful();
        $file = $this->manifestFromDisk()['clips']['fonemas/fonema_m']['files']['opus'];

        $ok = $this->get("/api/audio/v1/{$file['path']}?sha256={$file['sha256']}");
        $ok->assertOk()->assertHeader('Content-Type', 'audio/ogg');
        $this->assertStringContainsString('immutable', $ok->headers->get('Cache-Control'));
        $this->assertStringContainsString('max-age=31536000', $ok->headers->get('Cache-Control'));
        $this->assertSame(hash_file('sha256', $this->root.'/v1/'.$file['path']), hash('sha256', $ok->streamedContent()));

        $stale = $this->get("/api/audio/v1/{$file['path']}?sha256=deadbeef");
        $stale->assertOk();
        $this->assertStringNotContainsString('immutable', $stale->headers->get('Cache-Control'));

        $this->get('/api/audio/v1/fonemas/..%2F..%2F.env')->assertNotFound();
        $this->get('/api/audio/v1/secretos/fonema_m.opus')->assertNotFound();
        $this->get('/api/audio/v2/fonemas/fonema_m.opus')->assertNotFound();
        $this->get('/api/audio/v1/fonemas/fonema_x.opus')->assertNotFound();
    }
}
