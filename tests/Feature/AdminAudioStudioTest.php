<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\Admin\AudioStudioService;
use Database\Seeders\CurriculumSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class AdminAudioStudioTest extends TestCase
{
    use RefreshDatabase;

    public function test_non_admin_cannot_access_audio_studio(): void
    {
        $parent = User::factory()->create(['is_admin' => false]);

        $this->actingAs($parent)
            ->get('/gestion-leo/audio')
            ->assertForbidden();
    }

    public function test_admin_can_open_audio_studio_with_phonemes_words_and_mascot_scripts(): void
    {
        $this->seed(CurriculumSeeder::class);
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)
            ->get('/gestion-leo/audio')
            ->assertOk()
            ->assertSee('Estudio de Audio')
            ->assertSee('Fonema M (/m/)')
            ->assertSee('Sílabas (')
            ->assertSee('Instrucciones (')
            ->assertSee('ÁR · BOL')
            ->assertSee('Familia M')
            ->assertSee('¡Hola! Soy Leo, tu nuevo amigo.');
    }

    public function test_admin_can_upload_normalize_publish_and_delete_audio_clip(): void
    {
        $studio = app(AudioStudioService::class);
        if ($studio->resolveFfmpegBinary() === null) {
            $this->markTestSkipped('ffmpeg no está disponible en este entorno.');
        }

        $tmpRoot = sys_get_temp_dir().DIRECTORY_SEPARATOR.'leo_audio_studio_test_'.uniqid();
        mkdir($tmpRoot.DIRECTORY_SEPARATOR.'v1'.DIRECTORY_SEPARATOR.'fonemas', 0755, true);
        config()->set('audio.root', $tmpRoot);
        config()->set('audio.flutter_bundle_root', '');

        try {
            $admin = User::factory()->create(['is_admin' => true]);
            $wavPath = $this->createSampleWavFile($tmpRoot.DIRECTORY_SEPARATOR.'sample.wav');
            $upload = new UploadedFile($wavPath, 'fonema_l.wav', 'audio/wav', null, true);

            $response = $this->actingAs($admin)
                ->postJson('/gestion-leo/audio/upload', [
                    'category' => 'fonemas',
                    'clip_name' => 'fonema_l',
                    'audio' => $upload,
                ]);

            $response->assertOk()
                ->assertJsonPath('ok', true)
                ->assertJsonPath('clip_id', 'fonemas/fonema_l');

            $this->assertFileExists($tmpRoot.'/v1/fonemas/fonema_l.m4a');
            $this->assertFileExists($tmpRoot.'/v1/fonemas/fonema_l.opus');
            $this->assertFileExists($tmpRoot.'/v1/manifest.json');

            $manifest = json_decode(file_get_contents($tmpRoot.'/v1/manifest.json'), true);
            $this->assertArrayHasKey('fonemas/fonema_l', $manifest['clips']);

            // Nombre inválido sin prefijo obligatorio es rechazado con 422
            $badWav = $this->createSampleWavFile($tmpRoot.DIRECTORY_SEPARATOR.'bad.wav');
            $badUpload = new UploadedFile($badWav, 'invalido.wav', 'audio/wav', null, true);
            $this->actingAs($admin)
                ->postJson('/gestion-leo/audio/upload', [
                    'category' => 'fonemas',
                    'clip_name' => 'sin_prefijo',
                    'audio' => $badUpload,
                ])
                ->assertUnprocessable();

            // Eliminación limpia borra ambos formatos y actualiza manifiesto
            $this->actingAs($admin)
                ->deleteJson('/gestion-leo/audio/fonemas/fonema_l')
                ->assertOk()
                ->assertJsonPath('ok', true);

            $this->assertFileDoesNotExist($tmpRoot.'/v1/fonemas/fonema_l.m4a');
            $this->assertFileDoesNotExist($tmpRoot.'/v1/fonemas/fonema_l.opus');
        } finally {
            $this->removeDirectory($tmpRoot);
        }
    }

    /**
     * Genera un archivo WAV PCM real de 0.6 segundos (tono suave 440Hz) para probar ffmpeg.
     */
    private function createSampleWavFile(string $path): string
    {
        $sampleRate = 16000;
        $numSamples = (int) ($sampleRate * 0.6);
        $data = '';
        for ($i = 0; $i < $numSamples; $i++) {
            $sample = (int) (sin(2 * M_PI * 440 * $i / $sampleRate) * 12000);
            $data .= pack('v', $sample & 0xFFFF);
        }
        $dataSize = strlen($data);
        $header = 'RIFF'
            .pack('V', 36 + $dataSize)
            .'WAVEfmt '
            .pack('V', 16)
            .pack('v', 1)
            .pack('v', 1)
            .pack('V', $sampleRate)
            .pack('V', $sampleRate * 2)
            .pack('v', 2)
            .pack('v', 16)
            .'data'
            .pack('V', $dataSize);

        file_put_contents($path, $header.$data);

        return $path;
    }

    private function removeDirectory(string $dir): void
    {
        if (! is_dir($dir)) {
            return;
        }
        foreach (scandir($dir) ?: [] as $item) {
            if ($item === '.' || $item === '..') {
                continue;
            }
            $full = $dir.DIRECTORY_SEPARATOR.$item;
            is_dir($full) ? $this->removeDirectory($full) : @unlink($full);
        }
        @rmdir($dir);
    }
}
