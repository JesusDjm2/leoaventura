import 'speech_synthesizer.dart';

class _NoOpSpeechSynthesizer implements SpeechSynthesizer {
  @override
  Future<void> speak(
    String text, {
    String language = 'es-ES',
    double rate = 0.88,
  }) async {}

  @override
  Future<void> stop() async {}
}

SpeechSynthesizer createSpeechSynthesizer() => _NoOpSpeechSynthesizer();
