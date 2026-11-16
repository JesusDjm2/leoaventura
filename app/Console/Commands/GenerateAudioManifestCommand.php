<?php

namespace App\Console\Commands;

use App\Support\Audio\AudioManifestBuilder;
use Illuminate\Console\Command;
use RuntimeException;

class GenerateAudioManifestCommand extends Command
{
    protected $signature = 'audio:manifest
        {--audio-version= : Versión del catálogo (por defecto config audio.version)}
        {--root= : Raíz del catálogo (por defecto config audio.root)}
        {--strict : Falla si dos clips tienen el mismo hash}';

    protected $description = 'Genera manifest.json del catálogo de audio con el SHA-256 de cada clip';

    public function handle(): int
    {
        $version = (int) ($this->option('audio-version') ?: config('audio.version'));
        $builder = AudioManifestBuilder::fromConfig($this->option('root') ?: null);

        try {
            $manifest = $builder->build($version);
        } catch (RuntimeException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }

        foreach ($builder->warnings() as $w) {
            $this->warn("Clip duplicado: {$w}");
        }
        if ($this->option('strict') && $builder->warnings()) {
            $this->error('Modo --strict: hay clips duplicados.');

            return self::FAILURE;
        }
        if ($manifest['clip_count'] === 0) {
            $this->warn("El catálogo v{$version} está vacío.");
        }

        $path = $builder->write($version, $manifest);

        $this->table(
            ['Clip', 'Formatos', 'SHA-256 (opus)'],
            collect($manifest['clips'])->map(fn ($c, $id) => [
                $id,
                implode(', ', array_keys($c['files'])),
                substr($c['files']['opus']['sha256'] ?? '', 0, 16).'…',
            ])->values()->all(),
        );
        $this->info("Manifiesto v{$version}: {$manifest['clip_count']} clips, hash {$manifest['manifest_hash']}");
        $this->line("Escrito en {$path}");

        return self::SUCCESS;
    }
}
