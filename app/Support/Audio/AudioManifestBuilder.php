<?php

namespace App\Support\Audio;

use RuntimeException;

/**
 * Recorre <root>/v{n}/<categoria>/ y construye el manifiesto del catálogo:
 * un registro por clip con la ruta, tamaño y SHA-256 de cada formato.
 *
 * El manifiesto es determinista (sin marcas de tiempo, claves ordenadas):
 * el mismo conjunto de archivos produce byte a byte el mismo JSON y el mismo
 * manifest_hash, que los clientes usan para invalidar su caché.
 */
class AudioManifestBuilder
{
    public const SCHEMA = 1;

    public const NAME_PATTERN = '/^[a-z0-9]+(_[a-z0-9]+)*$/';

    /** @var list<string> */
    private array $warnings = [];

    public function __construct(
        private readonly string $root,
        private readonly array $categories,
        private readonly array $prefixes,
        private readonly array $formats,
    ) {}

    public static function fromConfig(?string $root = null): self
    {
        return new self(
            $root ?? config('audio.root'),
            config('audio.categories'),
            config('audio.prefixes'),
            config('audio.formats'),
        );
    }

    public function versionDir(int $version): string
    {
        return rtrim($this->root, '/\\').DIRECTORY_SEPARATOR.'v'.$version;
    }

    public function manifestPath(int $version): string
    {
        return $this->versionDir($version).DIRECTORY_SEPARATOR.'manifest.json';
    }

    /** @return list<string> */
    public function warnings(): array
    {
        return $this->warnings;
    }

    /**
     * @return array{schema:int, version:int, manifest_hash:string, clip_count:int, clips:array<string, array>}
     *
     * @throws RuntimeException si el catálogo no cumple la convención.
     */
    public function build(int $version): array
    {
        $this->warnings = [];
        $dir = $this->versionDir($version);
        if (! is_dir($dir)) {
            throw new RuntimeException("No existe el directorio del catálogo: {$dir}");
        }

        $extToFormat = array_flip($this->formats);
        $errors = [];
        $clips = [];

        foreach ($this->categories as $category) {
            $catDir = $dir.DIRECTORY_SEPARATOR.$category;
            if (! is_dir($catDir)) {
                continue;
            }
            $files = scandir($catDir) ?: [];
            sort($files, SORT_STRING);

            foreach ($files as $file) {
                $full = $catDir.DIRECTORY_SEPARATOR.$file;
                if ($file[0] === '.' || ! is_file($full)) {
                    continue; // .gitkeep, ocultos, subcarpetas
                }
                $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
                $name = pathinfo($file, PATHINFO_FILENAME);

                if (! isset($extToFormat[$ext])) {
                    $errors[] = "{$category}/{$file}: extensión no permitida (".implode(', ', $this->formats).')';

                    continue;
                }
                if (! preg_match(self::NAME_PATTERN, $name)) {
                    $errors[] = "{$category}/{$file}: el nombre debe ser snake_case ASCII en minúsculas";

                    continue;
                }
                $prefix = $this->prefixes[$category].'_';
                if (! str_starts_with($name, $prefix)) {
                    $errors[] = "{$category}/{$file}: el nombre debe empezar por '{$prefix}'";

                    continue;
                }

                $id = "{$category}/{$name}";
                $clips[$id] ??= ['category' => $category, 'name' => $name, 'files' => []];
                $clips[$id]['files'][$extToFormat[$ext]] = [
                    'path' => "{$category}/{$file}",
                    'bytes' => filesize($full),
                    'sha256' => hash_file('sha256', $full),
                ];
            }
        }

        foreach ($clips as $id => &$clip) {
            $missing = array_diff(array_keys($this->formats), array_keys($clip['files']));
            if ($missing) {
                $errors[] = "{$id}: faltan formatos (".implode(', ', $missing).')';
            }
            ksort($clip['files']);
        }
        unset($clip);

        if ($errors) {
            throw new RuntimeException("Catálogo inválido:\n - ".implode("\n - ", $errors));
        }

        // Dos clips con el mismo hash = el mismo audio bajo dos nombres.
        $seen = [];
        foreach ($clips as $id => $clip) {
            foreach ($clip['files'] as $f) {
                if (isset($seen[$f['sha256']])) {
                    $this->warnings[] = "{$f['path']} es idéntico a {$seen[$f['sha256']]}";
                }
                $seen[$f['sha256']] = $f['path'];
            }
        }

        ksort($clips, SORT_STRING);

        return [
            'schema' => self::SCHEMA,
            'version' => $version,
            'manifest_hash' => hash('sha256', $this->encode($clips)),
            'clip_count' => count($clips),
            'clips' => $clips,
        ];
    }

    public function encode(array $data): string
    {
        return json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)."\n";
    }

    public function write(int $version, array $manifest): string
    {
        $path = $this->manifestPath($version);
        $tmp = $path.'.tmp';
        file_put_contents($tmp, $this->encode($manifest));
        rename($tmp, $path); // reemplazo atómico: la API nunca sirve un JSON a medias

        return $path;
    }
}
