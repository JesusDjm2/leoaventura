import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'audio_manifest.dart';

class AudioIntegrityException implements Exception {
  AudioIntegrityException(this.path, this.expected, this.actual);
  final String path;
  final String expected;
  final String actual;
  @override
  String toString() =>
      'AudioIntegrityException($path): esperado $expected, recibido $actual';
}

class AudioDownloadException implements Exception {
  AudioDownloadException(this.path, this.statusCode);
  final String path;
  final int statusCode;
  @override
  String toString() => 'AudioDownloadException($path): HTTP $statusCode';
}

/// Resultado de aplicar un manifiesto nuevo a la caché.
class CacheSyncResult {
  final List<String> deleted = [];
  final List<String> downloaded = [];
  bool unchanged = false;

  @override
  String toString() =>
      'CacheSyncResult(unchanged: $unchanged, deleted: $deleted, downloaded: $downloaded)';
}

/// Caché en disco de clips descargados:
/// `<documentos>/audio/v{n}/<categoria>/<archivo>` + `index.json`.
///
/// `index.json` guarda el `manifest_hash` aplicado y el SHA-256 de cada archivo
/// en caché. Al recibir un manifiesto con otro hash se borran los archivos cuyo
/// hash cambió o que desaparecieron, y se vuelven a descargar los que cambiaron.
class AudioCache {
  AudioCache({
    required this.baseUrl,
    required this.httpClient,
    Future<Directory> Function()? rootDirectory,
  }) : _rootDirectory = rootDirectory ?? _defaultRoot;

  final Uri baseUrl;
  final http.Client httpClient;
  final Future<Directory> Function() _rootDirectory;

  /// Serializa las escrituras de `index.json` y las descargas concurrentes.
  Future<void> _lock = Future.value();
  final Map<String, Future<File>> _inflight = {};

  static Future<Directory> _defaultRoot() async => Directory(
      '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}audio');

  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final result = _lock.then((_) => fn());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Directory> versionDir(int version) async {
    final root = await _rootDirectory();
    return Directory('${root.path}${Platform.pathSeparator}v$version');
  }

  Future<File> _fileFor(int version, String path) async {
    final dir = await versionDir(version);
    return File('${dir.path}/${path.replaceAll('/', Platform.pathSeparator)}');
  }

  Future<File> _indexFile(int version) async =>
      File('${(await versionDir(version)).path}${Platform.pathSeparator}index.json');

  Future<_CacheIndex> _readIndex(int version) async {
    final f = await _indexFile(version);
    if (!await f.exists()) return _CacheIndex(null, {});
    try {
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return _CacheIndex(
        j['manifest_hash'] as String?,
        (j['files'] as Map<String, dynamic>).cast<String, String>(),
      );
    } on FormatException {
      return _CacheIndex(null, {}); // índice corrupto: se reconstruye
    }
  }

  Future<void> _writeIndex(int version, _CacheIndex index) async {
    final f = await _indexFile(version);
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode({
      'manifest_hash': index.manifestHash,
      'files': index.files,
    }));
    await tmp.rename(f.path);
  }

  /// Archivo en caché si existe y coincide con [entry.sha256].
  Future<File?> cachedFile(int version, AudioFileEntry entry) async {
    final index = await _readIndex(version);
    if (index.files[entry.path] != entry.sha256) return null;
    final f = await _fileFor(version, entry.path);
    return await f.exists() ? f : null;
  }

  /// Devuelve el archivo en caché o lo descarga (verificando su SHA-256).
  /// Llamadas concurrentes para el mismo archivo comparten la descarga.
  Future<File> ensureDownloaded(int version, AudioFileEntry entry) {
    final key = '$version/${entry.path}@${entry.sha256}';
    // Ojo: el callback NO debe devolver el Future eliminado (whenComplete lo
    // esperaría y el Future se esperaría a sí mismo: deadlock).
    return _inflight[key] ??= _download(version, entry).whenComplete(() {
      _inflight.remove(key);
    });
  }

  Future<File> _download(int version, AudioFileEntry entry) async {
    final existing = await cachedFile(version, entry);
    if (existing != null) return existing;

    final uri = baseUrl.resolve('/api/audio/v$version/${entry.path}')
        .replace(queryParameters: {'sha256': entry.sha256});
    final res = await httpClient.get(uri);
    if (res.statusCode != 200) {
      throw AudioDownloadException(entry.path, res.statusCode);
    }
    final actual = sha256.convert(res.bodyBytes).toString();
    if (actual != entry.sha256) {
      throw AudioIntegrityException(entry.path, entry.sha256, actual);
    }

    final file = await _fileFor(version, entry.path);
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(res.bodyBytes, flush: true);
    await tmp.rename(file.path); // atómico: nunca queda un clip a medias

    await _synchronized(() async {
      final index = await _readIndex(version);
      index.files[entry.path] = entry.sha256;
      await _writeIndex(version, index);
    });
    return file;
  }

  /// Aplica [manifest]: si su `manifest_hash` difiere del aplicado,
  /// borra lo obsoleto y vuelve a descargar los clips que cambiaron.
  /// También elimina carpetas de otras versiones (`v{k}` con k ≠ version).
  Future<CacheSyncResult> applyManifest(AudioManifest manifest) async {
    final result = CacheSyncResult();
    final version = manifest.version;
    final toRefresh = <AudioFileEntry>[];

    await _synchronized(() async {
      final root = await _rootDirectory();
      if (await root.exists()) {
        await for (final e in root.list()) {
          final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
          if (e is Directory && RegExp(r'^v\d+$').hasMatch(name) && name != 'v$version') {
            await e.delete(recursive: true);
            result.deleted.add('$name/*');
          }
        }
      }

      final index = await _readIndex(version);
      if (index.manifestHash == manifest.manifestHash) {
        result.unchanged = true;
        return;
      }

      for (final MapEntry(key: path, value: oldSha) in index.files.entries.toList()) {
        final newSha = manifest.shaForPath(path);
        if (newSha == oldSha) continue;
        final f = await _fileFor(version, path);
        if (await f.exists()) await f.delete();
        index.files.remove(path);
        result.deleted.add(path);
        if (newSha != null) {
          // Seguía en caché y cambió: se mantiene caliente con la versión nueva.
          toRefresh.add(manifest.clips.values
              .expand((c) => c.files.values)
              .firstWhere((fe) => fe.path == path));
        }
      }
      index.manifestHash = manifest.manifestHash;
      await _writeIndex(version, index);
    });

    for (final entry in toRefresh) {
      await ensureDownloaded(version, entry);
      result.downloaded.add(entry.path);
    }
    return result;
  }
}

class _CacheIndex {
  _CacheIndex(this.manifestHash, this.files);
  String? manifestHash;
  final Map<String, String> files;
}
