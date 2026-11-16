import 'dart:async';

import 'package:audio_session/audio_session.dart';

/// Fuente de eventos del sistema que afectan a la reproducción
/// (llamadas, alarmas, otra app que toma el audio, audífonos desconectados).
/// Abstraída para poder simular interrupciones en tests.
abstract class AudioFocus {
  Future<void> configure();
  Future<bool> setActive(bool active);
  Stream<AudioInterruptionEvent> get interruptions;

  /// Audífonos desconectados / salida de audio cambia a parlante.
  Stream<void> get becomingNoisy;
}

/// Implementación real sobre `audio_session` (AVAudioSession / AudioManager).
class AudioSessionFocus implements AudioFocus {
  AudioSession? _session;

  Future<AudioSession> get _s async => _session ??= await AudioSession.instance;

  @override
  Future<void> configure() async {
    // Perfil "speech": voz hablada, se pausa (no se mezcla) ante llamadas
    // y otras apps; respeta el modo silencio en iOS.
    await (await _s).configure(const AudioSessionConfiguration.speech());
  }

  @override
  Future<bool> setActive(bool active) async => (await _s).setActive(active);

  @override
  Stream<AudioInterruptionEvent> get interruptions async* {
    yield* (await _s).interruptionEventStream;
  }

  @override
  Stream<void> get becomingNoisy async* {
    yield* (await _s).becomingNoisyEventStream;
  }
}
