import 'web_clip_backend_stub.dart'
    if (dart.library.js_interop) 'web_clip_backend_web.dart' as impl;

/// Resultado de intentar reproducir un clip directamente con HTML5 Audio en Web.
enum WebClipPlayStatus {
  /// El clip comenzó a reproducirse correctamente.
  played,

  /// La reproducción fue cancelada porque llegó una petición más reciente o `stop()`.
  superseded,

  /// Falló la carga o reproducción del archivo (permite intentar respaldo).
  failed,
}

/// Motor ligero y determinista basado en `HTMLAudioElement` nativo para Flutter Web.
///
/// Evita reutilizar un único `<audio>` con estado atascado (como ocurre en
/// `just_audio_web` al cambiar de fuente o hacer `seek(0)` tras `completed`):
/// cada clip crea un elemento limpio y detiene/descarga por completo el anterior.
abstract interface class WebClipBackend {
  Future<WebClipPlayStatus> playUrl(String url);
  void stop();
}

/// Crea el backend nativo HTML5 en Web, o devuelve `null` en plataformas nativas
/// (donde se utiliza `just_audio`).
WebClipBackend? createWebClipBackend() => impl.createWebClipBackendImpl();
