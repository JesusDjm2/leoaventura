import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'speech_synthesizer.dart';

@JS('window')
external JSObject? get _window;

@JS('SpeechSynthesisUtterance')
extension type _JsSpeechSynthesisUtterance._(JSObject _) implements JSObject {
  external factory _JsSpeechSynthesisUtterance(String text);
  external set lang(String value);
  external set rate(double value);
  external set pitch(double value);
}

class _WebSpeechSynthesizer implements SpeechSynthesizer {
  JSObject? get _speechSynthesis {
    final win = _window;
    if (win == null) return null;
    final synth = win.getProperty<JSAny?>('speechSynthesis'.toJS);
    if (synth == null || synth.isUndefinedOrNull) return null;
    return synth as JSObject;
  }

  @override
  Future<void> speak(
    String text, {
    String language = 'es-ES',
    double rate = 0.88,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    try {
      final synth = _speechSynthesis;
      if (synth == null) return;

      // Cancela locución previa para que toques rápidos respondan al instante.
      synth.callMethod<JSAny?>('cancel'.toJS);

      final utterance = _JsSpeechSynthesisUtterance(cleaned)
        ..lang = language
        ..rate = rate
        ..pitch = 1.05;

      synth.callMethod<JSAny?>('speak'.toJS, utterance);
    } catch (_) {
      // Si el navegador bloquea autoplay antes del primer gesto, falla silenciosamente.
    }
  }

  @override
  Future<void> stop() async {
    try {
      _speechSynthesis?.callMethod<JSAny?>('cancel'.toJS);
    } catch (_) {}
  }
}

SpeechSynthesizer createSpeechSynthesizer() => _WebSpeechSynthesizer();
