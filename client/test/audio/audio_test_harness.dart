import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:leo_parvulos_app/audio/audio_focus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Registro global de operaciones de los reproductores simulados, en orden.
final List<String> platformLog = [];

/// Plataforma de `just_audio` simulada: en el host no hay motor de audio.
/// El `AudioPlayer` real de just_audio corre encima; esta capa simula el
/// decodificador (duración por archivo) y avanza la posición con timers reales.
class FakeJustAudioPlatform extends JustAudioPlatform {
  FakeJustAudioPlatform({this.durationFor = _defaultDuration});

  final Duration Function(String uri) durationFor;
  final Map<String, FakeAudioPlayerPlatform> players = {};

  static Duration _defaultDuration(String uri) => const Duration(milliseconds: 150);

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      players[request.id] = FakeAudioPlayerPlatform(request.id, durationFor);

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async {
    await players.remove(request.id)?.dispose(DisposeRequest());
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(DisposeAllPlayersRequest request) async {
    for (final p in players.values.toList()) {
      await p.dispose(DisposeRequest());
    }
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform(super.id, this.durationFor);

  final Duration Function(String uri) durationFor;
  final _events = StreamController<PlaybackEventMessage>.broadcast();
  final List<String> loadedUris = [];

  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration? _duration;
  Duration _basePos = Duration.zero;
  DateTime _since = DateTime.now();
  bool _running = false;
  Timer? _timer;

  Duration get _position {
    final p = _running ? _basePos + DateTime.now().difference(_since) : _basePos;
    final d = _duration;
    return d != null && p > d ? d : p;
  }

  void _emit() {
    if (_events.isClosed) return;
    _events.add(PlaybackEventMessage(
      processingState: _state,
      updateTime: DateTime.now(),
      updatePosition: _position,
      bufferedPosition: _duration ?? Duration.zero,
      duration: _duration,
      icyMetadata: null,
      currentIndex: 0,
      androidAudioSessionId: null,
    ));
  }

  void _schedule() {
    _timer?.cancel();
    final remaining = (_duration ?? Duration.zero) - _basePos;
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      _basePos = _duration ?? Duration.zero;
      _running = false;
      _state = ProcessingStateMessage.completed;
      platformLog.add('completed:$id');
      _emit();
    });
  }

  static List<String> _uris(AudioSourceMessage m) => switch (m) {
        UriAudioSourceMessage(:final uri) => [uri],
        ConcatenatingAudioSourceMessage(:final children) => children.expand(_uris).toList(),
        ClippingAudioSourceMessage(:final child) => _uris(child),
        LoopingAudioSourceMessage(:final child) => _uris(child),
        _ => [],
      };

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final uris = _uris(request.audioSourceMessage);
    loadedUris.addAll(uris);
    platformLog.add('load:$id:${uris.map((u) => u.split('/').last).join(',')}');
    _timer?.cancel();
    _running = false;
    _duration = uris.isEmpty ? Duration.zero : durationFor(uris.first);
    _basePos = request.initialPosition ?? Duration.zero;
    _state = ProcessingStateMessage.ready;
    _emit();
    return LoadResponse(duration: _duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    platformLog.add('play:$id');
    if (_state == ProcessingStateMessage.ready) {
      _since = DateTime.now();
      _running = true;
      _schedule();
    }
    _emit();
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    platformLog.add('pause:$id');
    _basePos = _position;
    _running = false;
    _timer?.cancel();
    _emit();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _basePos = request.position ?? Duration.zero;
    _since = DateTime.now();
    if (_state == ProcessingStateMessage.completed) _state = ProcessingStateMessage.ready;
    if (_running) _schedule();
    _emit();
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async => SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async => SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async => SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(SetSkipSilenceRequest request) async =>
      SetSkipSilenceResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();
  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
          SetAndroidAudioAttributesRequest request) async =>
      SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    _timer?.cancel();
    await _events.close();
    return DisposeResponse();
  }
}

/// Foco de audio simulado: el test inyecta llamadas entrantes, etc.
class FakeAudioFocus implements AudioFocus {
  final _interruptions = StreamController<AudioInterruptionEvent>.broadcast(sync: true);
  final _noisy = StreamController<void>.broadcast(sync: true);
  final List<bool> activations = [];
  bool configured = false;

  void interrupt({required bool begin, AudioInterruptionType type = AudioInterruptionType.pause}) =>
      _interruptions.add(AudioInterruptionEvent(begin, type));

  void unplugHeadphones() => _noisy.add(null);

  @override
  Future<void> configure() async => configured = true;

  @override
  Future<bool> setActive(bool active) async {
    activations.add(active);
    return true;
  }

  @override
  Stream<AudioInterruptionEvent> get interruptions => _interruptions.stream;

  @override
  Stream<void> get becomingNoisy => _noisy.stream;
}

/// `path_provider` simulado (just_audio copia los assets a un dir temporal).
class FakePathProvider extends PathProviderPlatform {
  FakePathProvider(this.root);
  final Directory root;

  @override
  Future<String?> getTemporaryPath() async => '${root.path}/tmp';

  @override
  Future<String?> getApplicationDocumentsPath() async => '${root.path}/documents';
}
