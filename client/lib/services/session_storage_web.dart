import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'session_storage.dart';

@JS('window')
external JSObject? get _window;

class _WebSessionStorage implements SessionStorage {
  JSObject? get _localStorage {
    final win = _window;
    if (win == null) return null;
    final storage = win.getProperty<JSAny?>('localStorage'.toJS);
    if (storage == null || storage.isUndefinedOrNull) return null;
    return storage as JSObject;
  }

  @override
  Future<String?> read(String key) async {
    try {
      final storage = _localStorage;
      if (storage == null) return null;
      final value = storage.callMethod<JSAny?>('getItem'.toJS, key.toJS);
      if (value == null || value.isUndefinedOrNull) return null;
      return (value as JSString).toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      _localStorage?.callMethod<JSAny?>('setItem'.toJS, key.toJS, value.toJS);
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    try {
      _localStorage?.callMethod<JSAny?>('removeItem'.toJS, key.toJS);
    } catch (_) {}
  }
}

SessionStorage createSessionStorage() => _WebSessionStorage();
