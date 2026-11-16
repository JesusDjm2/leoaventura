import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_cache.dart';
import 'audio_focus.dart';
import 'audio_manifest.dart';

typedef AudioPlayerFactory = AudioPlayer Function();

/// Reproducción de clips del catálogo con preload, caché y manejo de
/// interrupciones. Ver `docs/audio/AUDIO_SERVICE.md`.
///
/// Resolución de cada clip (en orden):
/// 1. **Asset empaquetado** si su SHA-256 coincide con el del manifiesto vigente.
/// 2. **Caché en disco** (`<documentos>/audio/v{n}/`), descargando si falta.
class AudioService {
  AudioService({
    required this.cache,
    required this.focus,
    AudioFormat? format,
    AudioPlayerFactory? playerFactory,
    AssetBundle? bundle,
    this.bundledManifestAsset = 'assets/audio/v1/manifest.json',
  })  : format = format ?? defaultFormat(),
        _bundle = bundle ?? rootBundle,
        _players = List.generate(2, (_) => (playerFactory ?? _defaultPlayer)());

  final AudioCache cache;
  final AudioFocus focus;
  final AudioFormat format;
  final String bundledManifestAsset;
  final AssetBundle _bundle;

  /// Doble buffer: mientras uno suena, el otro precarga el siguiente clip.
  final List<AudioPlayer> _players;

  AudioManifest? _bundled;
  AudioManifest? _server;
  AudioPlayer? _active;
  _QueueToken? _queue;
  bool _resumeAfterInterruption = false;
  final List<StreamSubscription<dynamic>> _subs = [];
  final _currentClip = StreamController<String?>.broadcast();
  String? _currentClipId;

  /// Clip que está sonando (o pausado), o null.
  String? get currentClip => _currentClipId;
  Stream<String?> get currentClipStream => _currentClip.stream;

  /// Manifiesto con el que se resuelven los clips (servidor > empaquetado).
  AudioManifest? get manifest => _server ?? _bundled;

  @visibleForTesting
  AudioPlayer? get activePlayer => _active;

  @visibleForTesting
  List<AudioPlayer> get players => List.unmodifiable(_players);

  /// Opus en Android/Web/escritorio; AAC en Apple (sin Opus nativo fiable).
  static AudioFormat defaultFormat() {
    if (kIsWeb) return AudioFormat.opus;
    return Platform.isIOS || Platform.isMacOS ? AudioFormat.aac : AudioFormat.opus;
  }

  static AudioPlayer _defaultPlayer() => AudioPlayer(
        // Las interrupciones y la activación de la sesión las gestiona este
        // servicio (una sola política para los dos reproductores).
        handleInterruptions: false,
        handleAudioSessionActivation: false,
      );

  /// Configura la sesión de audio, escucha interrupciones y carga el
  /// manifiesto empaquetado (si existe).
  Future<void> init() async {
    await focus.configure();
    _subs.add(focus.interruptions.listen(_onInterruption));
    _subs.add(focus.becomingNoisy.listen((_) {
      // Audífonos desconectados: pausar y NO reanudar solo (evita que suene
      // de golpe por el parlante en la sala).
      _resumeAfterInterruption = false;
      _active?.pause();
    }));
    try {
      _bundled = AudioManifest.parse(await _bundle.loadString(bundledManifestAsset));
    } on FlutterError {
      _bundled = null; // build sin audio empaquetado
    }
  }

  /// Aplica el manifiesto del servidor: invalida la caché si cambió su hash.
  Future<CacheSyncResult> updateManifest(AudioManifest serverManifest) async {
    final result = await cache.applyManifest(serverManifest);
    _server = serverManifest;
    return result;
  }

  Future<void> play(String clipId) => playQueue([clipId]);

  /// Reproduce [clipIds] en orden. Cancela cualquier cola anterior.
  /// Completa cuando termina el último clip o la cola se detiene.
  Future<void> playQueue(List<String> clipIds) async {
    await stop();
    if (clipIds.isEmpty) return;
    final token = _queue = _QueueToken();
    await focus.setActive(true);

    var current = _players[0];
    var spare = _players[1];
    await current.setAudioSource(await sourceFor(clipIds.first));

    for (var i = 0; i < clipIds.length; i++) {
      if (token.cancelled) return;
      _active = current;
      _setCurrent(clipIds[i]);

      // Preload del siguiente mientras suena el actual.
      Future<bool>? preload;
      if (i + 1 < clipIds.length) preload = _preload(spare, clipIds[i + 1]);

      unawaited(current.play().catchError((Object _) {}));
      await Future.any([
        current.processingStateStream.firstWhere((s) => s == ProcessingState.completed),
        token.done,
      ]);
      if (token.cancelled) return;
      // just_audio deja `playing == true` al completar; sin esta pausa, al
      // reutilizar este reproductor (doble buffer) su play() sería un no-op.
      await current.pause();

      if (preload != null) {
        final ok = await preload;
        (current, spare) = (spare, current);
        // Si el preload falló, se reintenta aquí para propagar el error.
        if (!ok) await current.setAudioSource(await sourceFor(clipIds[i + 1]));
      }
    }

    if (identical(_queue, token)) {
      _queue = null;
      _active = null;
      _setCurrent(null);
      await focus.setActive(false);
    }
  }

  Future<bool> _preload(AudioPlayer player, String clipId) async {
    try {
      await player.setAudioSource(await sourceFor(clipId), preload: true);
      return true;
    } catch (e) {
      debugPrint('[AudioService] preload de $clipId falló: $e');
      return false;
    }
  }

  Future<void> pause() async {
    _resumeAfterInterruption = false;
    await _active?.pause();
  }

  Future<void> resume() async => _active?.play();

  Future<void> stop() async {
    _queue?.cancel();
    _queue = null;
    _resumeAfterInterruption = false;
    _active = null;
    _setCurrent(null);
    await Future.wait(_players.map((p) => p.stop()));
  }

  /// Resuelve la fuente de un clip: asset empaquetado vigente o caché/descarga.
  @visibleForTesting
  Future<AudioSource> sourceFor(String clipId) async {
    final m = manifest;
    final entry = m?.clips[clipId];
    if (m == null || entry == null) {
      throw ArgumentError.value(clipId, 'clipId', 'no está en el manifiesto');
    }
    final file = entry.file(format) ??
        (throw StateError('$clipId no tiene formato ${format.key}'));

    final bundledFile = _bundled?.clips[clipId]?.file(format);
    if (bundledFile != null && bundledFile.sha256 == file.sha256) {
      return AudioSource.asset('assets/audio/v${_bundled!.version}/${file.path}', tag: clipId);
    }
    final local = await cache.ensureDownloaded(m.version, file);
    return AudioSource.file(local.path, tag: clipId);
  }

  void _onInterruption(AudioInterruptionEvent e) {
    final p = _active;
    if (p == null) return;
    if (e.begin) {
      // Voz para niños: también se pausa ante "duck" (bajar volumen dejaría
      // el fonema ininteligible bajo otra voz, p. ej. el GPS).
      if (p.playing) {
        _resumeAfterInterruption = e.type != AudioInterruptionType.unknown;
        p.pause();
      }
    } else {
      // `unknown` al terminar = el sistema no garantiza que debamos reanudar.
      if (_resumeAfterInterruption && e.type != AudioInterruptionType.unknown) {
        unawaited(p.play().catchError((Object _) {}));
      }
      _resumeAfterInterruption = false;
    }
  }

  void _setCurrent(String? id) {
    _currentClipId = id;
    if (!_currentClip.isClosed) _currentClip.add(id);
  }

  Future<void> dispose() async {
    _queue?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await Future.wait(_players.map((p) => p.dispose()));
    await _currentClip.close();
  }
}

class _QueueToken {
  final _done = Completer<void>();
  bool get cancelled => _done.isCompleted;
  Future<void> get done => _done.future;
  void cancel() {
    if (!_done.isCompleted) _done.complete();
  }
}
