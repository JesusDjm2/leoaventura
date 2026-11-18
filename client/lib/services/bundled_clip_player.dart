import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../audio/audio_manifest.dart';

/// Contrato para reproducir clips humanos empaquetados (`assets/audio/v1/`).
abstract interface class ClipAudioPlayer {
  Future<void> ensureInitialized();
  bool hasClip(String clipId);
  Future<bool> playClip(String clipId);
  Future<void> stop();
}

/// Reproductor multiplataforma (Web, Android, iOS, Desktop) basado en `just_audio`
/// que consume `assets/audio/v1/manifest.json` sin depender de `dart:io`.
///
/// Prioriza `.m4a` (AAC) en Web y Apple por compatibilidad universal en navegadores,
/// y `.opus` en Android/Linux/Windows, con fallback automático al otro formato.
class BundledClipAudioPlayer implements ClipAudioPlayer {
  final AssetBundle _bundle;
  final String manifestAssetPath;
  final AudioPlayer Function() _playerFactory;

  AudioManifest? _manifest;
  AudioPlayer? _player;
  Future<void>? _initFuture;

  BundledClipAudioPlayer({
    AssetBundle? bundle,
    this.manifestAssetPath = 'assets/audio/v1/manifest.json',
    AudioPlayer Function()? playerFactory,
  })  : _bundle = bundle ?? rootBundle,
        _playerFactory = playerFactory ?? _createDefaultPlayer;

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
    return _initFuture ??= _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final raw = await _bundle.loadString(manifestAssetPath);
      _manifest = AudioManifest.parse(raw);
    } catch (e) {
      debugPrint('[BundledClipAudioPlayer] No se pudo cargar el manifiesto: $e');
      _manifest = null;
    }
  }

  @override
  bool hasClip(String clipId) {
    final m = _manifest;
    if (m == null) return false;
    return m.clips.containsKey(clipId);
  }

  String? _resolveAssetPath(String clipId) {
    final m = _manifest;
    final entry = m?.clips[clipId];
    if (m == null || entry == null) return null;

    final preferred = entry.file(_preferredFormat) ??
        entry.file(AudioFormat.aac) ??
        entry.file(AudioFormat.opus);
    if (preferred == null) return null;
    return 'assets/audio/v${m.version}/${preferred.path}';
  }

  @override
  Future<bool> playClip(String clipId) async {
    await ensureInitialized();
    final assetPath = _resolveAssetPath(clipId);
    if (assetPath == null) return false;

    try {
      final player = _player ??= _playerFactory();
      await player.stop();
      await player.setAsset(assetPath);
      await player.play();
      return true;
    } catch (e) {
      debugPrint('[BundledClipAudioPlayer] Error reproduciendo $clipId ($assetPath): $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
