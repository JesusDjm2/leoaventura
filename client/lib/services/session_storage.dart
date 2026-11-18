import 'session_storage_io.dart'
    if (dart.library.js_interop) 'session_storage_web.dart' as platform_storage;

/// Almacenamiento ligero clave-valor para persistir la sesión parental y el
/// progreso local del niño entre recargas y cierres de la app.
abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Implementación en memoria para pruebas deterministas y aislamiento entre tests.
class InMemorySessionStorage implements SessionStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

/// Crea el almacenamiento persistente adecuado para la plataforma actual
/// (`localStorage` en Web; archivo en documentos de la app en Android/iOS/Desktop).
SessionStorage createPlatformSessionStorage() =>
    platform_storage.createSessionStorage();
