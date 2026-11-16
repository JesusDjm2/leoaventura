import 'dart:convert';

/// Formatos que genera `scripts/normalize_audio.sh`.
enum AudioFormat {
  /// Opus en contenedor Ogg (Android, Web, escritorio).
  opus('opus'),

  /// AAC-LC en MP4 (iOS, macOS, Safari).
  aac('aac');

  const AudioFormat(this.key);

  /// Clave del formato en el manifiesto (`files.opus`, `files.aac`).
  final String key;
}

class AudioFileEntry {
  const AudioFileEntry({
    required this.path,
    required this.bytes,
    required this.sha256,
  });

  /// Ruta relativa a la carpeta de la versión, p. ej. `fonemas/fonema_m.opus`.
  final String path;
  final int bytes;
  final String sha256;

  factory AudioFileEntry.fromJson(Map<String, dynamic> j) => AudioFileEntry(
        path: j['path'] as String,
        bytes: j['bytes'] as int,
        sha256: j['sha256'] as String,
      );
}

class AudioClipEntry {
  const AudioClipEntry({
    required this.id,
    required this.category,
    required this.name,
    required this.files,
  });

  /// `<categoria>/<nombre>`, p. ej. `fonemas/fonema_m`.
  final String id;
  final String category;
  final String name;
  final Map<String, AudioFileEntry> files;

  AudioFileEntry? file(AudioFormat f) => files[f.key];
}

/// Manifiesto del catálogo de audio (`GET /api/audio/manifest` o el
/// `manifest.json` empaquetado). Ver `docs/audio/PIPELINE.md`.
class AudioManifest {
  const AudioManifest({
    required this.version,
    required this.manifestHash,
    required this.clips,
  });

  final int version;
  final String manifestHash;
  final Map<String, AudioClipEntry> clips;

  factory AudioManifest.fromJson(Map<String, dynamic> j) {
    final clips = <String, AudioClipEntry>{};
    (j['clips'] as Map<String, dynamic>).forEach((id, raw) {
      final c = raw as Map<String, dynamic>;
      clips[id] = AudioClipEntry(
        id: id,
        category: c['category'] as String,
        name: c['name'] as String,
        files: {
          for (final e in (c['files'] as Map<String, dynamic>).entries)
            e.key: AudioFileEntry.fromJson(e.value as Map<String, dynamic>),
        },
      );
    });
    return AudioManifest(
      version: j['version'] as int,
      manifestHash: j['manifest_hash'] as String,
      clips: clips,
    );
  }

  factory AudioManifest.parse(String json) =>
      AudioManifest.fromJson(jsonDecode(json) as Map<String, dynamic>);

  /// Hash vigente de un archivo por su ruta relativa, o null si ya no existe.
  String? shaForPath(String path) {
    for (final c in clips.values) {
      for (final f in c.files.values) {
        if (f.path == path) return f.sha256;
      }
    }
    return null;
  }
}
