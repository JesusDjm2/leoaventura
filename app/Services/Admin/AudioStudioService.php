<?php

namespace App\Services\Admin;

use App\Models\CurriculumLevel;
use App\Support\Audio\AudioManifestBuilder;
use Illuminate\Http\UploadedFile;
use RuntimeException;
use Symfony\Component\Process\Process;

class AudioStudioService
{
    /**
     * Construye el inventario completo del Estudio de Audio combinando:
     * 1. Fonemas activos del currículo (dinámicos desde `curriculum_levels`)
     * 2. Palabras ejemplo del currículo
     * 3. Los 25 guiones oficiales de la mascota León Leo
     *
     * @return array<string, mixed>
     */
    public function inventory(): array
    {
        $version = (int) config('audio.version', 1);
        $builder = AudioManifestBuilder::fromConfig();
        $versionDir = $builder->versionDir($version);

        $levels = CurriculumLevel::query()
            ->orderBy('unit')
            ->orderBy('order_index')
            ->get();

        $phonemes = [];
        $words = [];

        foreach ($levels as $level) {
            $letter = mb_strtolower(trim($level->letter));
            $slug = $letter === 'ñ' ? 'enie' : preg_replace('/[^a-z0-9]+/u', '_', $letter);
            $upper = mb_strtoupper($letter);

            $phonemeClip = "fonema_{$slug}";
            $phonemes[] = $this->hydrateSlot([
                'category' => 'fonemas',
                'clip_name' => $phonemeClip,
                'badge' => $upper,
                'title' => "Fonema {$upper} ({$level->phoneme})",
                'script' => "Pronuncia solo el sonido puro {$level->phoneme} (~1 segundo, sin decir el nombre de la letra).",
                'hint' => "Ejemplo: {$level->example_word} · Unidad {$level->unit}",
            ], $versionDir, $version);

            $wordSlug = $this->asciiSlug($level->example_word);
            $wordClip = "palabra_{$wordSlug}";
            $words[] = $this->hydrateSlot([
                'category' => 'palabras',
                'clip_name' => $wordClip,
                'badge' => $upper,
                'title' => $level->example_word,
                'script' => "Di con voz clara y alegre: \"{$level->example_word}\".",
                'hint' => "Palabra asociada a la letra {$upper} ({$level->phoneme})",
            ], $versionDir, $version);
        }

        $mascot = [];
        foreach ($this->mascotScripts() as $item) {
            $mascot[] = $this->hydrateSlot([
                'category' => 'mascota',
                'clip_name' => 'mascota_'.$item['id'],
                'badge' => 'LEO',
                'title' => $item['context'],
                'script' => $item['text'],
                'hint' => "Tono: {$item['tone']}",
            ], $versionDir, $version);
        }

        $syllables = [];
        foreach ($this->syllableSpecs($levels) as $item) {
            $syllables[] = $this->hydrateSlot([
                'category' => 'silabas',
                'clip_name' => 'silaba_'.$item['slug'],
                'badge' => $item['display'],
                'title' => "Sílaba {$item['display']}",
                'script' => "Pronuncia clara y alegre la sílaba \"{$item['display']}\".",
                'hint' => $item['hint'],
            ], $versionDir, $version);
        }

        $syllablesByClip = [];
        foreach ($syllables as $s) {
            $syllablesByClip[$s['clip_name']] = $s;
        }
        $syllableGroups = $this->buildSyllableGroups($levels, $syllablesByClip);

        $instructions = [];
        foreach ($this->instructionScripts() as $item) {
            $instructions[] = $this->hydrateSlot([
                'category' => 'instrucciones',
                'clip_name' => 'instruccion_'.$item['id'],
                'badge' => 'INS',
                'title' => $item['title'],
                'script' => $item['text'],
                'hint' => $item['context'],
            ], $versionDir, $version);
        }

        $all = [...$phonemes, ...$words, ...$syllables, ...$instructions, ...$mascot];
        $recorded = count(array_filter($all, static fn (array $s): bool => $s['recorded']));

        return [
            'ffmpeg_available' => $this->resolveFfmpegBinary() !== null,
            'stats' => [
                'total' => count($all),
                'recorded' => $recorded,
                'pending' => count($all) - $recorded,
                'percent' => count($all) > 0 ? (int) round(($recorded / count($all)) * 100) : 0,
            ],
            'groups' => [
                'fonemas' => $phonemes,
                'palabras' => $words,
                'silabas' => $syllables,
                'instrucciones' => $instructions,
                'mascota' => $mascot,
            ],
            'syllable_groups' => $syllableGroups,
        ];
    }

    /**
     * Recibe una grabación del navegador o archivo subido, lo normaliza a -16 LUFS
     * (recorte de silencios + mono 48kHz), exporta `.m4a` y `.opus`, regenera
     * `manifest.json` y sincroniza el bundle local de Flutter si existe.
     *
     * @return array<string, mixed>
     */
    public function processAndPublish(string $category, string $clipName, UploadedFile $file): array
    {
        $this->assertValidSlot($category, $clipName);

        $ffmpeg = $this->resolveFfmpegBinary();
        if ($ffmpeg === null) {
            throw new RuntimeException(
                'No se encontró ffmpeg en el servidor. Configura FFMPEG_BINARY en .env o instala ffmpeg.'
            );
        }

        $version = (int) config('audio.version', 1);
        $root = rtrim((string) config('audio.root'), '/\\');
        $rawDir = $root.DIRECTORY_SEPARATOR.'raw'.DIRECTORY_SEPARATOR.$category;
        $outDir = $root.DIRECTORY_SEPARATOR.'v'.$version.DIRECTORY_SEPARATOR.$category;

        $this->ensureDirectory($rawDir);
        $this->ensureDirectory($outDir);

        $rawExt = strtolower($file->getClientOriginalExtension() ?: 'webm');
        if (! preg_match('/^[a-z0-9]{2,5}$/', $rawExt)) {
            $rawExt = 'webm';
        }

        $rawPath = $rawDir.DIRECTORY_SEPARATOR.$clipName.'.'.$rawExt;
        $file->move($rawDir, $clipName.'.'.$rawExt);

        $m4aTmp = $outDir.DIRECTORY_SEPARATOR.$clipName.'.tmp.m4a';
        $opusTmp = $outDir.DIRECTORY_SEPARATOR.$clipName.'.tmp.opus';
        $m4aFinal = $outDir.DIRECTORY_SEPARATOR.$clipName.'.m4a';
        $opusFinal = $outDir.DIRECTORY_SEPARATOR.$clipName.'.opus';

        // Filtro profesional: recorte suave de silencios + normalización -16 LUFS para niños
        $audioFilter = 'silenceremove=start_periods=1:start_silence=0.12:start_threshold=-45dB,'
            .'areverse,silenceremove=start_periods=1:start_silence=0.12:start_threshold=-45dB,areverse,'
            .'loudnorm=I=-16:TP=-1.5:LRA=11';

        try {
            $this->runFfmpeg([
                $ffmpeg, '-y', '-hide_banner', '-loglevel', 'error',
                '-i', $rawPath,
                '-ac', '1', '-ar', '48000',
                '-af', $audioFilter,
                '-c:a', 'aac', '-b:a', '64k', '-movflags', '+faststart',
                $m4aTmp,
            ]);

            $this->runFfmpeg([
                $ffmpeg, '-y', '-hide_banner', '-loglevel', 'error',
                '-i', $rawPath,
                '-ac', '1', '-ar', '48000',
                '-af', $audioFilter,
                '-c:a', 'libopus', '-b:a', '32k', '-vbr', 'on', '-application', 'voip',
                $opusTmp,
            ]);

            @rename($m4aTmp, $m4aFinal);
            @rename($opusTmp, $opusFinal);
        } catch (\Throwable $e) {
            @unlink($m4aTmp);
            @unlink($opusTmp);
            throw $e;
        }

        $builder = AudioManifestBuilder::fromConfig();
        $manifest = $builder->build($version);
        $builder->write($version, $manifest);

        $this->syncToFlutterBundle($version, $category, $clipName, $m4aFinal, $opusFinal, $builder->manifestPath($version));

        $sha = hash_file('sha256', $m4aFinal) ?: '';

        return [
            'clip_id' => "{$category}/{$clipName}",
            'category' => $category,
            'clip_name' => $clipName,
            'bytes_m4a' => filesize($m4aFinal) ?: 0,
            'bytes_opus' => filesize($opusFinal) ?: 0,
            'manifest_hash' => $manifest['manifest_hash'],
            'preview_url' => url("/api/audio/v{$version}/{$category}/{$clipName}.m4a?sha256={$sha}"),
        ];
    }

    /**
     * Elimina un clip grabado y actualiza el manifiesto atómicamente.
     */
    public function deleteClip(string $category, string $clipName): void
    {
        $this->assertValidSlot($category, $clipName);

        $version = (int) config('audio.version', 1);
        $builder = AudioManifestBuilder::fromConfig();
        $catDir = $builder->versionDir($version).DIRECTORY_SEPARATOR.$category;

        foreach (['m4a', 'opus'] as $ext) {
            $path = $catDir.DIRECTORY_SEPARATOR.$clipName.'.'.$ext;
            if (is_file($path)) {
                @unlink($path);
            }
        }

        $manifest = $builder->build($version);
        $builder->write($version, $manifest);

        // Limpiar también del bundle local de Flutter si existe
        $flutterRoot = (string) config('audio.flutter_bundle_root');
        if ($flutterRoot !== '' && is_dir($flutterRoot)) {
            $flutterVersionDir = rtrim($flutterRoot, '/\\').DIRECTORY_SEPARATOR.'v'.$version;
            foreach (['m4a', 'opus'] as $ext) {
                $target = $flutterVersionDir.DIRECTORY_SEPARATOR.$category.DIRECTORY_SEPARATOR.$clipName.'.'.$ext;
                if (is_file($target)) {
                    @unlink($target);
                }
            }
            if (is_file($builder->manifestPath($version))) {
                @copy($builder->manifestPath($version), $flutterVersionDir.DIRECTORY_SEPARATOR.'manifest.json');
            }
        }
    }

    /**
     * Autodetecta `ffmpeg` en configuración, PATH del sistema o imageio-ffmpeg de Python.
     */
    public function resolveFfmpegBinary(): ?string
    {
        $configured = trim((string) config('audio.ffmpeg_binary', ''));
        if ($configured !== '' && is_file($configured)) {
            return $configured;
        }

        $probe = new Process(['ffmpeg', '-version']);
        $probe->setTimeout(4);
        $probe->run();
        if ($probe->isSuccessful()) {
            return 'ffmpeg';
        }

        // Búsqueda determinista de imageio-ffmpeg en Windows / entornos locales Python
        $patterns = [
            getenv('LOCALAPPDATA').'\\Programs\\Python\\Python*\\Lib\\site-packages\\imageio_ffmpeg\\binaries\\ffmpeg*.exe',
            getenv('USERPROFILE').'\\AppData\\Local\\Programs\\Python\\Python*\\Lib\\site-packages\\imageio_ffmpeg\\binaries\\ffmpeg*.exe',
            '/usr/bin/ffmpeg',
            '/usr/local/bin/ffmpeg',
        ];

        foreach ($patterns as $pattern) {
            $matches = glob($pattern) ?: [];
            foreach ($matches as $candidate) {
                if (is_file($candidate)) {
                    return $candidate;
                }
            }
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $slot
     * @return array<string, mixed>
     */
    private function hydrateSlot(array $slot, string $versionDir, int $version): array
    {
        $cat = $slot['category'];
        $name = $slot['clip_name'];
        $m4aPath = $versionDir.DIRECTORY_SEPARATOR.$cat.DIRECTORY_SEPARATOR.$name.'.m4a';
        $opusPath = $versionDir.DIRECTORY_SEPARATOR.$cat.DIRECTORY_SEPARATOR.$name.'.opus';
        $recorded = is_file($m4aPath) && is_file($opusPath);
        $sha = $recorded ? (hash_file('sha256', $m4aPath) ?: '') : null;

        return [
            ...$slot,
            'clip_id' => "{$cat}/{$name}",
            'recorded' => $recorded,
            'bytes' => $recorded ? (filesize($m4aPath) ?: 0) : 0,
            'preview_url' => $recorded
                ? url("/api/audio/v{$version}/{$cat}/{$name}.m4a?sha256={$sha}")
                : null,
        ];
    }

    private function assertValidSlot(string $category, string $clipName): void
    {
        $categories = config('audio.categories', []);
        $prefixes = config('audio.prefixes', []);

        if (! in_array($category, $categories, true)) {
            throw new RuntimeException("Categoría de audio inválida: {$category}");
        }
        if (! preg_match(AudioManifestBuilder::NAME_PATTERN, $clipName)) {
            throw new RuntimeException("Nombre de clip inválido: {$clipName}");
        }
        $prefix = ($prefixes[$category] ?? '').'_';
        if (! str_starts_with($clipName, $prefix)) {
            throw new RuntimeException("El clip '{$clipName}' debe comenzar con '{$prefix}'.");
        }
    }

    /**
     * @param  list<string>  $command
     */
    private function runFfmpeg(array $command): void
    {
        $process = new Process($command);
        $process->setTimeout(45);
        $process->run();

        if (! $process->isSuccessful()) {
            $err = trim($process->getErrorOutput() ?: $process->getOutput());
            throw new RuntimeException('Error procesando el audio con ffmpeg: '.($err !== '' ? $err : 'código '.$process->getExitCode()));
        }
    }

    private function syncToFlutterBundle(
        int $version,
        string $category,
        string $clipName,
        string $m4aSource,
        string $opusSource,
        string $manifestSource,
    ): void {
        $flutterRoot = trim((string) config('audio.flutter_bundle_root', ''));
        if ($flutterRoot === '' || ! is_dir(dirname($flutterRoot))) {
            return;
        }

        $targetVersionDir = rtrim($flutterRoot, '/\\').DIRECTORY_SEPARATOR.'v'.$version;
        $targetCatDir = $targetVersionDir.DIRECTORY_SEPARATOR.$category;
        $this->ensureDirectory($targetCatDir);

        @copy($m4aSource, $targetCatDir.DIRECTORY_SEPARATOR.$clipName.'.m4a');
        @copy($opusSource, $targetCatDir.DIRECTORY_SEPARATOR.$clipName.'.opus');
        if (is_file($manifestSource)) {
            @copy($manifestSource, $targetVersionDir.DIRECTORY_SEPARATOR.'manifest.json');
        }
    }

    private function ensureDirectory(string $path): void
    {
        if (! is_dir($path)) {
            mkdir($path, 0755, true);
        }
    }

    private function asciiSlug(string $value): string
    {
        $map = [
            'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u', 'ü' => 'u',
            'Á' => 'a', 'É' => 'e', 'Í' => 'i', 'Ó' => 'o', 'Ú' => 'u', 'Ü' => 'u',
            'ñ' => 'nn', 'Ñ' => 'nn',
        ];
        $lower = mb_strtolower(strtr(trim($value), $map));
        $clean = preg_replace('/[^a-z0-9]+/', '_', $lower) ?? '';

        return trim($clean, '_') ?: 'palabra';
    }

    /**
     * Mapa oficial de sílabas por palabra del currículo.
     *
     * @return array<string, list<string>>
     */
    private function wordSyllableMap(): array
    {
        return [
            'Árbol' => ['ÁR', 'BOL'],
            'Elefante' => ['E', 'LE', 'FAN', 'TE'],
            'Isla' => ['IS', 'LA'],
            'Oso' => ['O', 'SO'],
            'Uva' => ['U', 'VA'],
            'Mamá' => ['MA', 'MÁ'],
            'Pato' => ['PA', 'TO'],
            'Sol' => ['SO', 'L'],
            'Luna' => ['LU', 'NA'],
            'Tortuga' => ['TOR', 'TU', 'GA'],
            'Nube' => ['NU', 'BE'],
            'Dado' => ['DA', 'DO'],
            'Flor' => ['FLO', 'R'],
            'Ratón' => ['RA', 'TÓN'],
            'Ballena' => ['BA', 'LLE', 'NA'],
            'Casa' => ['CA', 'SA'],
            'Gato' => ['GA', 'TO'],
            'Jirafa' => ['JI', 'RA', 'FA'],
            'Vaca' => ['VA', 'CA'],
            'Ñandú' => ['ÑAN', 'DÚ'],
        ];
    }

    /**
     * Organiza las sílabas en grupos compactos (por palabra y por familia consonántica)
     * para evitar listas largas interminables en el Estudio de Audio.
     *
     * @param  \Illuminate\Support\Collection<int, CurriculumLevel>  $levels
     * @param  array<string, array<string, mixed>>  $syllablesByClip
     * @return array{words: list<array<string, mixed>>, families: list<array<string, mixed>>}
     */
    private function buildSyllableGroups($levels, array $syllablesByClip): array
    {
        $wordMap = $this->wordSyllableMap();
        $wordGroups = [];

        foreach ($wordMap as $word => $parts) {
            $slots = [];
            $seen = [];
            foreach ($parts as $part) {
                $clipName = 'silaba_'.$this->asciiSlug($part);
                if (isset($seen[$clipName]) || ! isset($syllablesByClip[$clipName])) {
                    continue;
                }
                $seen[$clipName] = true;
                $slots[] = [
                    ...$syllablesByClip[$clipName],
                    'badge' => $part,
                ];
            }
            $recorded = count(array_filter($slots, static fn (array $s): bool => $s['recorded']));
            $wordGroups[] = [
                'id' => 'word_'.$this->asciiSlug($word),
                'title' => $word,
                'subtitle' => implode(' · ', $parts),
                'recorded' => $recorded,
                'total' => count($slots),
                'slots' => $slots,
            ];
        }

        $vowels = ['a', 'e', 'i', 'o', 'u'];
        $familyGroups = [];
        foreach ($levels as $level) {
            $letter = mb_strtolower(trim($level->letter));
            if ($letter === '' || in_array($letter, $vowels, true)) {
                continue;
            }
            $upper = mb_strtoupper($letter);
            $slots = [];
            $labels = [];
            foreach ($vowels as $v) {
                $combo = mb_strtoupper($letter.$v);
                $clipName = 'silaba_'.$this->asciiSlug($combo);
                if (isset($syllablesByClip[$clipName])) {
                    $slots[] = [
                        ...$syllablesByClip[$clipName],
                        'badge' => $combo,
                    ];
                    $labels[] = $combo;
                }
            }
            $recorded = count(array_filter($slots, static fn (array $s): bool => $s['recorded']));
            $familyGroups[] = [
                'id' => 'family_'.$this->asciiSlug($letter),
                'title' => "Familia {$upper}",
                'subtitle' => implode(' · ', $labels),
                'recorded' => $recorded,
                'total' => count($slots),
                'slots' => $slots,
            ];
        }

        return [
            'words' => $wordGroups,
            'families' => $familyGroups,
        ];
    }

    /**
     * Construye la lista deduplicada de sílabas usadas en el Constructor de Sílabas
     * (consonante + vocal) y en el minijuego de Lectura de Palabras (ej. ÁR, BOL, PA, TO).
     *
     * @param  \Illuminate\Support\Collection<int, CurriculumLevel>  $levels
     * @return list<array{slug: string, display: string, hint: string}>
     */
    private function syllableSpecs($levels): array
    {
        $wordSyllables = $this->wordSyllableMap();

        $map = [];
        // 1. Sílabas de las palabras de lectura
        foreach ($wordSyllables as $word => $parts) {
            foreach ($parts as $part) {
                $slug = $this->asciiSlug($part);
                if ($slug === '' || isset($map[$slug])) {
                    continue;
                }
                $map[$slug] = [
                    'slug' => $slug,
                    'display' => $part,
                    'hint' => "Usada en \"{$word}\"",
                ];
            }
        }

        // 2. Combinaciones consonante + vocal para el Constructor de Sílabas
        $vowels = ['a', 'e', 'i', 'o', 'u'];
        foreach ($levels as $level) {
            $letter = mb_strtolower(trim($level->letter));
            if ($letter === '' || in_array($letter, $vowels, true)) {
                continue;
            }
            foreach ($vowels as $v) {
                $combo = mb_strtoupper($letter.$v);
                $slug = $this->asciiSlug($combo);
                if (! isset($map[$slug])) {
                    $map[$slug] = [
                        'slug' => $slug,
                        'display' => $combo,
                        'hint' => 'Constructor de sílabas ('.mb_strtoupper($letter).' + '.mb_strtoupper($v).')',
                    ];
                }
            }
        }

        return array_values($map);
    }

    /**
     * Consignas oficiales de los 4 minijuegos.
     *
     * @return list<array{id: string, title: string, text: string, context: string}>
     */
    private function instructionScripts(): array
    {
        return [
            ['id' => 'traza_letra', 'title' => 'Trazar letra (inicio)', 'text' => '¡Hola! Traza la letra con tu dedito siguiendo los puntos.', 'context' => 'Minijuego 1 · Trazado'],
            ['id' => 'sonido_match', 'title' => 'Emparejar sonido (inicio)', 'text' => 'Escucha el sonido y toca el dibujo que empieza igual.', 'context' => 'Minijuego 2 · Sonido'],
            ['id' => 'silaba_junta', 'title' => 'Constructor de sílabas (inicio)', 'text' => 'Junta la letra con una vocal para formar una sílaba mágica.', 'context' => 'Minijuego 3 · Sílabas'],
            ['id' => 'leer_silabas', 'title' => 'Leer palabra (inicio)', 'text' => 'Toca cada sílaba para leer la palabra y luego elige su dibujo.', 'context' => 'Minijuego 4 · Leer'],
            ['id' => 'reintentar', 'title' => 'Reintentar trazo', 'text' => 'Vamos de nuevo, ¡tú puedes lograrlo con calma!', 'context' => 'Botón reintentar'],
            ['id' => 'excelente', 'title' => 'Felicitación general', 'text' => '¡Excelente trabajo! Lo hiciste increíble.', 'context' => 'Acierto en minijuegos'],
            ['id' => 'casi_intenta', 'title' => 'Ánimo ante intento fallido', 'text' => '¡Casi! Prueba con otro dibujo, tú puedes.', 'context' => 'Error empático'],
        ];
    }

    /**
     * @return list<array{id: string, text: string, tone: string, context: string}>
     */
    private function mascotScripts(): array
    {
        return [
            ['id' => 'onb_saludo', 'text' => '¡Hola! Soy Leo, tu nuevo amigo.', 'tone' => 'ánimo', 'context' => 'Bienvenida'],
            ['id' => 'onb_avatar', 'text' => 'Toca a tu compañero de juego.', 'tone' => 'instrucción', 'context' => 'Bienvenida'],
            ['id' => 'onb_listos', 'text' => '¡Listos para aprender a leer juntos!', 'tone' => 'celebración', 'context' => 'Bienvenida'],
            ['id' => 'onb_sonido', 'text' => 'Escucha cómo suena este lindo rugido.', 'tone' => 'instrucción', 'context' => 'Bienvenida'],
            ['id' => 'ins_traza_m', 'text' => 'Traza la letra M con tu dedito.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'ins_sonido_m', 'text' => 'La letra M suena mmm, mamá.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'ins_sigue_puntos', 'text' => 'Sigue los puntos amarillos despacio.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'ins_une_silaba', 'text' => 'Junta la letra con la vocal.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'ins_busca_dibujo', 'text' => 'Encuentra el dibujo que empieza igual.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'ins_toca_pantalla', 'text' => 'Toca la letra para escucharla.', 'tone' => 'instrucción', 'context' => 'Instrucciones'],
            ['id' => 'exi_bien_hecho', 'text' => '¡Muy bien hecho, campeón!', 'tone' => 'celebración', 'context' => 'Éxito'],
            ['id' => 'exi_estrella', 'text' => '¡Ganaste una estrella brillante!', 'tone' => 'celebración', 'context' => 'Éxito'],
            ['id' => 'exi_perfecto', 'text' => '¡Excelente trazo, lo hiciste genial!', 'tone' => 'celebración', 'context' => 'Éxito'],
            ['id' => 'exi_sonido_m', 'text' => '¡Mmm, qué rico suena esa letra!', 'tone' => 'celebración', 'context' => 'Éxito'],
            ['id' => 'exi_palabra', 'text' => '¡Descubriste una palabra nueva!', 'tone' => 'celebración', 'context' => 'Éxito'],
            ['id' => 'err_cerca', 'text' => '¡Muy cerca! Inténtalo otra vez.', 'tone' => 'ánimo', 'context' => 'Ánimo'],
            ['id' => 'err_vamos', 'text' => '¡Tú puedes, hazlo con calma!', 'tone' => 'ánimo', 'context' => 'Ánimo'],
            ['id' => 'err_otra_vez', 'text' => 'Probemos de nuevo con tu dedito.', 'tone' => 'ánimo', 'context' => 'Ánimo'],
            ['id' => 'err_animo', 'text' => '¡Casi lo logras, sigue practicando!', 'tone' => 'ánimo', 'context' => 'Ánimo'],
            ['id' => 'err_respira', 'text' => 'No pasa nada, jugamos otra vez.', 'tone' => 'ánimo', 'context' => 'Ánimo'],
            ['id' => 'tra_siguiente', 'text' => '¡Vamos a la siguiente aventura!', 'tone' => 'ánimo', 'context' => 'Transiciones'],
            ['id' => 'tra_menu', 'text' => 'Volvamos a nuestro mapa mágico.', 'tone' => 'ánimo', 'context' => 'Transiciones'],
            ['id' => 'tra_descanso', 'text' => '¡Gran trabajo, descansamos un ratito!', 'tone' => 'celebración', 'context' => 'Transiciones'],
            ['id' => 'tra_mundo_nuevo', 'text' => '¡Desbloqueaste un mundo de letras!', 'tone' => 'celebración', 'context' => 'Transiciones'],
            ['id' => 'tra_adios', 'text' => '¡Hasta luego, amiguito lector!', 'tone' => 'ánimo', 'context' => 'Transiciones'],
        ];
    }
}
