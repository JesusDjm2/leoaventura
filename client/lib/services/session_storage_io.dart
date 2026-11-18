import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'session_storage.dart';

class _FileSessionStorage implements SessionStorage {
  final Map<String, String> _memoryFallback = {};

  bool get _isWidgetTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  Future<File?> _fileFor(String key) async {
    if (_isWidgetTest) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      return File('${dir.path}${Platform.pathSeparator}$safeName.json');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> read(String key) async {
    final file = await _fileFor(key);
    if (file == null) return _memoryFallback[key];
    try {
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  @override
  Future<void> write(String key, String value) async {
    _memoryFallback[key] = value;
    final file = await _fileFor(key);
    if (file == null) return;
    try {
      await file.writeAsString(value, flush: true);
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    _memoryFallback.remove(key);
    final file = await _fileFor(key);
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

SessionStorage createSessionStorage() => _FileSessionStorage();
