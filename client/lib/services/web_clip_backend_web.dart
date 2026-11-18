import 'dart:js_interop';
import 'web_clip_backend.dart';

@JS('Audio')
extension type _JsAudio._(JSObject _) implements JSObject {
  external factory _JsAudio([String url]);
  external set preload(String value);
  external set currentTime(num value);
  external void pause();
  external void load();
  external void removeAttribute(String name);
  external JSPromise<JSAny?> play();
}

class _Html5WebClipBackend implements WebClipBackend {
  _JsAudio? _activeAudio;
  int _generation = 0;

  void _disposeElement(_JsAudio? audio) {
    if (audio == null) return;
    try {
      audio.pause();
    } catch (_) {}
    try {
      audio.currentTime = 0;
    } catch (_) {}
    try {
      audio.removeAttribute('src');
      audio.load();
    } catch (_) {}
  }

  @override
  void stop() {
    _generation++;
    final previous = _activeAudio;
    _activeAudio = null;
    _disposeElement(previous);
  }

  @override
  Future<WebClipPlayStatus> playUrl(String url) async {
    // Detiene y descarta por completo cualquier clip previo (imposible repetir el anterior).
    stop();
    final gen = _generation;

    _JsAudio? audio;
    try {
      audio = _JsAudio(url)..preload = 'auto';
      _activeAudio = audio;

      await audio.play().toDart;

      if (gen != _generation) {
        _disposeElement(audio);
        return WebClipPlayStatus.superseded;
      }
      return WebClipPlayStatus.played;
    } catch (_) {
      if (gen != _generation) {
        _disposeElement(audio);
        return WebClipPlayStatus.superseded;
      }
      if (identical(_activeAudio, audio)) {
        _activeAudio = null;
      }
      _disposeElement(audio);
      return WebClipPlayStatus.failed;
    }
  }
}

WebClipBackend? createWebClipBackendImpl() => _Html5WebClipBackend();
