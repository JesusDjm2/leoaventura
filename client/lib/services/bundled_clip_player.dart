import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../audio/audio_manifest.dart';
import 'session_sync_service.dart';
import 'web_clip_backend.dart';

/// Contrato para reproducir clips humanos empaquetados o publicados en el servidor.
abstract interface class ClipAudioPlayer {
  Future<void> ensureInitialized();
  bool hasClip(String clipId);
  Future<bool> playClip(String clipId);
  Future<void> stop();
}

/// Normaliza cualquier palabra o sílaba en español a slug ASCII compatible con
/// la convención del catálogo (`ÁR` -> `ar`, `MÁ` -> `ma`, `Ñandú` -> `nnandu`).
String normalizeAudioSlug(String raw) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'nn',
  };
  var s = raw.trim().toLowerCase();
  replacements.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return s.replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Reproductor multiplataforma (Web, Android, iOS, Desktop):
/// - En **Web**: usa [WebClipBackend] (`HTMLAudioElement` nativo aislado por clip),
///   deteniendo y vaciando por completo cualquier audio anterior para evitar el
///   re-disparo o arrastre de fuentes viejas de `just_audio_web`.
/// - En **Android/iOS/Desktop**: usa `just_audio` con cancelación por secuencia.
///
/// Resolución inteligente (permite escuchar grabaciones nuevas del Estudio de Audio
/// al instante sin recompilar, manteniendo soporte 100% offline):
/// 1. **Manifiesto vivo del servidor (`/api/audio/manifest`):** reproduce vía
///    `/api/audio/v{n}/{path}?sha256=...`.
/// 2. **Asset empaquetado (`assets/audio/v1/`):** respaldo offline instantáneo.
class BundledClipAudioPlayer implements ClipAudioPlayer {
  final AssetBundle _bundle;
  final String manifestAssetPath;
  final AudioPlayer Function() _playerFactory;
  final WebClipBackend? _webBackend;
  final http.Client? _httpClient;
  final String? _apiBaseUrl;

  AudioManifest? _bundledManifest;
  AudioManifest? _remoteManifest;
  AudioPlayer? _player;
  String? _loadedSource;
  int _nativeSeq = 0;
  Future<void>? _initFuture;

  BundledClipAudioPlayer({
    AssetBundle? bundle,
    this.manifestAssetPath = 'assets/audio/v1/manifest.json',
    AudioPlayer Function()? playerFactory,
    WebClipBackend? webBackend,
    http.Client? httpClient,
    String? apiBaseUrl,
  })  : _bundle = bundle ?? rootBundle,
        _playerFactory = playerFactory ?? _createDefaultPlayer,
        _webBackend = webBackend ??
            (kIsWeb && playerFactory == null ? createWebClipBackend() : null),
        _httpClient = httpClient,
        _apiBaseUrl = apiBaseUrl;

  static AudioPlayer _createDefaultPlayer() => AudioPlayer();

  AudioFormat get _preferredFormat {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AudioFormat.aac;
    }
    return AudioFormat.opus;
  }

  @override
  Future<void> ensureInitialized() {
    return _initFuture ??= _loadManifests();
  }

  /// Fuerza la recarga del manifiesto remoto (útil si se acaban de grabar audios).
  Future<void> refreshRemoteManifest() async {
    await _loadRemoteManifest();
  }

  Future<void> _loadManifests() async {
    try {
      final raw = await _bundle.loadString(manifestAssetPath);
      _bundledManifest = AudioManifest.parse(raw);
    } catch (e) {
      debugPrint('[BundledClipAudioPlayer] No se pudo cargar manifiesto empaquetado: $e');
      _bundledManifest = null;
    }

    await _loadRemoteManifest();
  }

  Future<void> _loadRemoteManifest() async {
    final baseUrl = AppSessionState.resolveApiBaseUrl(_apiBaseUrl);
    final client = _httpClient ?? http.Client();
    final ownsClient = _httpClient == null;
    try {
      final cacheBust = DateTime.now().millisecondsSinceEpoch;
      final resp = await client
          .get(
            Uri.parse('$baseUrl/api/audio/manifest?_=$cacheBust'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        _remoteManifest = AudioManifest.parse(resp.body);
      }
    } catch (_) {
      // Sin conexión al backend: continúa sin problemas usando assets locales.
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  String? _canonicalIdIn(AudioManifest? manifest, String clipId) {
    if (manifest == null) return null;
    if (manifest.clips.containsKey(clipId)) return clipId;

    final parts = clipId.split('/');
    if (parts.length == 2) {
      final cat = parts[0];
      final rawName = parts[1];
      final slug = normalizeAudioSlug(rawName);
      const prefixes = {
        'fonemas': 'fonema_',
        'palabras': 'palabra_',
        'silabas': 'silaba_',
        'instrucciones': 'instruccion_',
        'mascota': 'mascota_',
      };
      final prefix = prefixes[cat];
      if (prefix != null) {
        final candidates = [
          if (!rawName.startsWith(prefix)) '$cat/$prefix$rawName',
          if (slug.isNotEmpty && !slug.startsWith(prefix)) '$cat/$prefix$slug',
          if (slug.isNotEmpty) '$cat/$slug',
        ];
        for (final candidate in candidates) {
          if (manifest.clips.containsKey(candidate)) return candidate;
        }
      }
    }
    return null;
  }

  @override
  bool hasClip(String clipId) {
    return _canonicalIdIn(_remoteManifest, clipId) != null ||
        _canonicalIdIn(_bundledManifest, clipId) != null;
  }

  List<String> _resolveWebCandidateUrls(String clipId) {
    final urls = <String>[];
    final remoteId = _canonicalIdIn(_remoteManifest, clipId);
    final bundledId = _canonicalIdIn(_bundledManifest, clipId);

    // 1. Siempre priorizar el clip vivo del servidor con su SHA-256 actual
    //    (evita depender de la caché de assets de `flutter run` al grabar nuevos clips).
    if (remoteId != null && _remoteManifest != null) {
      final remoteEntry = _remoteManifest!.clips[remoteId]!;
      final remoteFile = remoteEntry.file(_preferredFormat) ??
          remoteEntry.file(AudioFormat.aac) ??
          remoteEntry.file(AudioFormat.opus);
      if (remoteFile != null) {
        final baseUrl = AppSessionState.resolveApiBaseUrl(_apiBaseUrl);
        urls.add(
          '$baseUrl/api/audio/v${_remoteManifest!.version}/${remoteFile.path}?sha256=${remoteFile.sha256}',
        );
      }
    }

    // 2. Respaldo offline: asset empaquetado servido directamente por Flutter Web.
    if (bundledId != null && _bundledManifest != null) {
      final bundledEntry = _bundledManifest!.clips[bundledId]!;
      final bundledFile = bundledEntry.file(_preferredFormat) ??
          bundledEntry.file(AudioFormat.aac) ??
          bundledEntry.file(AudioFormat.opus);
      if (bundledFile != null) {
        urls.add(
          'assets/assets/audio/v${_bundledManifest!.version}/${bundledFile.path}',
        );
      }
    }

    return urls;
  }

  ({String source, bool isUrl})? _resolveNativeSource(String clipId) {
    final remoteId = _canonicalIdIn(_remoteManifest, clipId);
    final bundledId = _canonicalIdIn(_bundledManifest, clipId);

    if (remoteId != null && _remoteManifest != null) {
      final remoteEntry = _remoteManifest!.clips[remoteId]!;
      final remoteFile = remoteEntry.file(_preferredFormat) ??
          remoteEntry.file(AudioFormat.aac) ??
          remoteEntry.file(AudioFormat.opus);

      if (remoteFile != null) {
        final bundledFile = bundledId != null
            ? _bundledManifest?.clips[bundledId]?.file(_preferredFormat)
            : null;
        final sameAsBundled =
            bundledFile != null && bundledFile.sha256 == remoteFile.sha256;

        if (!sameAsBundled) {
          final baseUrl = AppSessionState.resolveApiBaseUrl(_apiBaseUrl);
          final url =
              '$baseUrl/api/audio/v${_remoteManifest!.version}/${remoteFile.path}?sha256=${remoteFile.sha256}';
          return (source: url, isUrl: true);
        }
      }
    }

    if (bundledId != null && _bundledManifest != null) {
      final entry = _bundledManifest!.clips[bundledId]!;
      final file = entry.file(_preferredFormat) ??
          entry.file(AudioFormat.aac) ??
          entry.file(AudioFormat.opus);
      if (file != null) {
        return (
          source: 'assets/audio/v${_bundledManifest!.version}/${file.path}',
          isUrl: false,
        );
      }
    }

    return null;
  }

  @override
  Future<bool> playClip(String clipId) async {
    await ensureInitialized();

    // Ruta Web dedicada: HTMLAudioElement nuevo por clip + descarga total del anterior.
    final webBackend = _webBackend;
    if (webBackend != null) {
      final urls = _resolveWebCandidateUrls(clipId);
      if (urls.isEmpty) return false;

      for (final url in urls) {
        final status = await webBackend.playUrl(url);
        if (status == WebClipPlayStatus.played ||
            status == WebClipPlayStatus.superseded) {
          return true;
        }
      }
      return false;
    }

    // Ruta nativa (Android / iOS / Desktop): `just_audio` con cancelación por secuencia.
    final resolved = _resolveNativeSource(clipId);
    if (resolved == null) return false;

    final played = await _playResolvedNative(resolved, recreatePlayer: false);
    if (played) return true;

    return _playResolvedNative(resolved, recreatePlayer: true);
  }

  Future<bool> _playResolvedNative(
    ({String source, bool isUrl}) resolved, {
    required bool recreatePlayer,
  }) async {
    final seq = ++_nativeSeq;
    try {
      if (recreatePlayer && _player != null) {
        final old = _player;
        _player = null;
        _loadedSource = null;
        unawaited(old?.dispose().catchError((Object _) {}));
      }

      final player = _player ??= _playerFactory();

      // `stop()` garantiza `playing == false` antes de cambiar fuente o hacer seek(0).
      await player.stop();
      if (seq != _nativeSeq) return true;

      if (_loadedSource == resolved.source) {
        await player.seek(Duration.zero);
      } else {
        if (resolved.isUrl) {
          await player.setUrl(resolved.source);
        } else {
          await player.setAsset(resolved.source);
        }
        if (seq != _nativeSeq) return true;
        _loadedSource = resolved.source;
        await player.seek(Duration.zero);
      }

      if (seq != _nativeSeq) return true;

      unawaited(player.play().catchError((Object e) {
        debugPrint('[BundledClipAudioPlayer] Error en play() (${resolved.source}): $e');
      }));
      return true;
    } catch (e) {
      if (seq != _nativeSeq) return true;
      debugPrint('[BundledClipAudioPlayer] Error reproduciendo (${resolved.source}): $e');
      _loadedSource = null;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _nativeSeq++;
    _webBackend?.stop();
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
