import 'speech_synthesizer_stub.dart'
    if (dart.library.js_interop) 'speech_synthesizer_web.dart' as platform_tts;

/// Abstracción multiplataforma de síntesis de voz en español.
///
/// En Web delega en `window.speechSynthesis` (`es-ES` / `es-MX`) con ritmo pausado
/// para párvulos; en otras plataformas o tests usa un respaldo seguro sin errores.
abstract interface class SpeechSynthesizer {
  Future<void> speak(String text, {String language = 'es-ES', double rate = 0.88});
  Future<void> stop();
}

/// Crea la implementación nativa de la plataforma actual.
SpeechSynthesizer createPlatformSpeechSynthesizer() =>
    platform_tts.createSpeechSynthesizer();
