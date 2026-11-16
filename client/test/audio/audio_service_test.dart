// Tests de integración del AudioService: AudioPlayer real de just_audio sobre
// una plataforma simulada, assets reales empaquetados, caché real en disco
// (path_provider apuntando a un directorio temporal) y servidor HTTP simulado.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:leo_parvulos_app/audio/audio_cache.dart';
import 'package:leo_parvulos_app/audio/audio_manifest.dart';
import 'package:leo_parvulos_app/audio/audio_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'audio_test_harness.dart';

String sha(List<int> b) => sha256.convert(b).toString();

/// Construye un manifiesto como el de `php artisan audio:manifest`.
AudioManifest manifestOf(int version, Map<String, List<int>> files) {
  final clips = <String, Map<String, dynamic>>{};
  for (final MapEntry(key: path, value: bytes) in files.entries) {
    final id = path.substring(0, path.lastIndexOf('.'));
    final ext = path.split('.').last;
    final c = clips[id] ??= {
      'category': id.split('/').first,
      'name': id.split('/').last,
      'files': <String, dynamic>{},
    };
    (c['files'] as Map)[ext == 'opus' ? 'opus' : 'aac'] = {
      'path': path,
      'bytes': bytes.length,
      'sha256': sha(bytes),
    };
  }
  return AudioManifest.fromJson({
    'version': version,
    'manifest_hash': sha(utf8.encode(jsonEncode(clips))),
    'clips': clips,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late FakeJustAudioPlatform platform;
  late FakeAudioFocus focus;
  late Map<String, List<int>> serverFiles;
  late List<Uri> requests;
  late AudioCache cache;
  late AudioService service;

  Future<AudioService> buildService({
    Duration Function(String uri)? durationFor,
  }) async {
    platform = FakeJustAudioPlatform(
      durationFor: durationFor ?? (_) => const Duration(milliseconds: 150),
    );
    JustAudioPlatform.instance = platform;
    service = AudioService(cache: cache, focus: focus, format: AudioFormat.opus);
    await service.init();
    return service;
  }

  /// Reproductor simulado que cargó [clipFile] (AudioPlayer no expone su id).
  FakeAudioPlayerPlatform platformThatLoaded(String clipFile) => platform.players.values
      .firstWhere((fp) => fp.loadedUris.any((u) => u.endsWith(clipFile)));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('leo_audio_test_');
    PathProviderPlatform.instance = FakePathProvider(tmp);
    platformLog.clear();
    focus = FakeAudioFocus();
    serverFiles = {};
    requests = [];
    cache = AudioCache(
      baseUrl: Uri.parse('https://api.test'),
      httpClient: MockClient((req) async {
        requests.add(req.url);
        final path = req.url.path.replaceFirst(RegExp(r'^/api/audio/v\d+/'), '');
        final bytes = serverFiles[path];
        return bytes == null
            ? http.Response('not found', 404)
            : http.Response.bytes(bytes, 200);
      }),
    );
  });

  tearDown(() async {
    await service.dispose();
    await tmp.delete(recursive: true);
  });

  group('reproducción', () {
    test('reproduce un clip desde assets y el AudioPlayer reporta completed', () async {
      await buildService();
      expect(focus.configured, isTrue);
      expect(service.manifest?.clips, contains('fonemas/fonema_m'));

      final states = <ProcessingState>[];
      final player = service.players.first;
      final sub = player.processingStateStream.listen(states.add);

      await service.play('fonemas/fonema_m').timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(player.processingState, ProcessingState.completed);
      expect(states, containsAllInOrder([ProcessingState.ready, ProcessingState.completed]));

      // Se reprodujo el asset empaquetado real (just_audio lo copia a disco):
      // mismos bytes que el manifiesto, sin tocar la red.
      final uri = platformThatLoaded('fonema_m.opus').loadedUris.single;
      expect(uri, endsWith('fonemas/fonema_m.opus'));
      final played = await File.fromUri(Uri.parse(uri)).readAsBytes();
      expect(sha(played), service.manifest!.clips['fonemas/fonema_m']!.file(AudioFormat.opus)!.sha256);
      expect(requests, isEmpty);
      expect(focus.activations, [true, false]);
      expect(service.currentClip, isNull);
    });

    test('preload: el siguiente clip se carga en el otro reproductor antes de que termine el actual',
        () async {
      await buildService(durationFor: (_) => const Duration(milliseconds: 400));
      await service
          .playQueue(['fonemas/fonema_m', 'fonemas/fonema_s', 'fonemas/fonema_a'])
          .timeout(const Duration(seconds: 10));
      final ida = platformThatLoaded('fonema_m.opus').id;
      final idb = platformThatLoaded('fonema_s.opus').id;
      expect(ida, isNot(idb), reason: 'dos reproductores (doble buffer)');

      String loadOf(String id, String clip) => 'load:$id:$clip.opus';
      final log = platformLog;
      final completedA = log.indexOf('completed:$ida');
      final completedB = log.indexOf('completed:$idb');
      // 1º clip suena en A; mientras tanto B ya precargó el 2º.
      expect(log.indexOf(loadOf(idb, 'fonema_s')), lessThan(completedA));
      // Al terminar A, B arranca sin ninguna carga entre medio.
      final playB = log.indexOf('play:$idb', completedA);
      expect(playB, greaterThan(completedA));
      expect(log.sublist(completedA, playB).where((e) => e.startsWith('load:')), isEmpty);
      // Y A (ya libre) precarga el 3º antes de que termine B.
      expect(log.indexOf(loadOf(ida, 'fonema_a')), allOf(greaterThan(completedA), lessThan(completedB)));
      expect(log.where((e) => e.startsWith('completed:')), hasLength(3));
      expect(service.players.every((p) => p.processingState == ProcessingState.completed), isTrue);
    });
  });

  group('caché', () {
    test('manifiesto con hash nuevo: borra el clip viejo y descarga el nuevo', () async {
      await buildService();
      const path = 'fonemas/fonema_m.opus';
      final v1Bytes = utf8.encode('fonema m — grabación original');
      final v2Bytes = utf8.encode('fonema m — regrabado tras revisión fonoaudiológica');

      // Servidor con una versión de fonema_m distinta de la empaquetada.
      serverFiles[path] = v1Bytes;
      final m1 = manifestOf(1, {path: v1Bytes});
      await service.updateManifest(m1);
      await service.play('fonemas/fonema_m');

      final cached = File('${tmp.path}/documents/audio/v1/fonemas/fonema_m.opus'
          .replaceAll('/', Platform.pathSeparator));
      expect(await cached.readAsBytes(), v1Bytes);
      expect(requests.single.queryParameters['sha256'], sha(v1Bytes));
      expect(platformThatLoaded('fonema_m.opus').loadedUris.last, contains('documents'));

      // Mismo manifiesto otra vez: nada cambia, no hay red.
      final same = await service.updateManifest(m1);
      expect(same.unchanged, isTrue);
      expect(requests, hasLength(1));

      // Nuevo manifest_hash: el clip viejo se borra y se descarga el nuevo.
      serverFiles[path] = v2Bytes;
      final m2 = manifestOf(1, {path: v2Bytes});
      expect(m2.manifestHash, isNot(m1.manifestHash));
      final result = await service.updateManifest(m2);

      expect(result.deleted, [path]);
      expect(result.downloaded, [path]);
      expect(requests, hasLength(2));
      expect(requests.last.queryParameters['sha256'], sha(v2Bytes));
      expect(await cached.readAsBytes(), v2Bytes);
      final index = jsonDecode(await File('${cached.parent.parent.path}/index.json').readAsString());
      expect(index['manifest_hash'], m2.manifestHash);
      expect(index['files'][path], sha(v2Bytes));

      // La siguiente reproducción usa el clip nuevo sin volver a descargar.
      await service.play('fonemas/fonema_m');
      expect(requests, hasLength(2));
    });

    test('clip eliminado del manifiesto se borra; cambio de versión borra v1 completa', () async {
      await buildService();
      final bytes = utf8.encode('palabra mama');
      serverFiles['palabras/palabra_mama.opus'] = bytes;
      await service.updateManifest(manifestOf(1, {'palabras/palabra_mama.opus': bytes}));
      await service.play('palabras/palabra_mama');
      final v1Dir = Directory('${tmp.path}/documents/audio/v1');
      expect(await v1Dir.exists(), isTrue);

      final r = await service.updateManifest(manifestOf(1, {'fonemas/fonema_x.opus': [1, 2, 3]}));
      expect(r.deleted, ['palabras/palabra_mama.opus']);
      expect(r.downloaded, isEmpty);

      await service.updateManifest(manifestOf(2, {'fonemas/fonema_x.opus': [1, 2, 3]}));
      expect(await v1Dir.exists(), isFalse);
    });

    test('descarga con hash que no coincide se rechaza y no queda en caché', () async {
      await buildService();
      const path = 'fonemas/fonema_m.opus';
      final expected = utf8.encode('correcto');
      serverFiles[path] = utf8.encode('corrupto en tránsito');
      await service.updateManifest(manifestOf(1, {path: expected}));

      await expectLater(service.play('fonemas/fonema_m'), throwsA(isA<AudioIntegrityException>()));
      expect(File('${tmp.path}/documents/audio/v1/fonemas/fonema_m.opus').existsSync(), isFalse);
    });
  });

  group('interrupciones (audio_session)', () {
    test('llamada entrante pausa el audio y al terminar lo reanuda', () async {
      await buildService(durationFor: (_) => const Duration(milliseconds: 600));
      final player = service.players.first;

      final playback = service.play('fonemas/fonema_m');
      await player.playingStream.firstWhere((p) => p);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Entra una llamada.
      focus.interrupt(begin: true, type: AudioInterruptionType.pause);
      expect(player.playing, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final pausedAt = player.position;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(player.position, pausedAt, reason: 'no avanza mientras dura la llamada');
      expect(player.processingState, isNot(ProcessingState.completed));
      expect(pausedAt, lessThan(const Duration(milliseconds: 600)));

      // Termina la llamada.
      focus.interrupt(begin: false, type: AudioInterruptionType.pause);
      expect(player.playing, isTrue);
      await playback.timeout(const Duration(seconds: 5));
      expect(player.processingState, ProcessingState.completed);
      final id = platformThatLoaded('fonema_m.opus').id;
      final untilCompleted = platformLog.sublist(0, platformLog.indexOf('completed:$id'));
      expect(
        untilCompleted.where((e) => e.startsWith('pause:') || e.startsWith('play:')).toList(),
        ['play:$id', 'pause:$id', 'play:$id'],
      );
    });

    test('interrupción "unknown" y audífonos desconectados pausan sin reanudar', () async {
      await buildService(durationFor: (_) => const Duration(milliseconds: 800));
      final player = service.players.first;

      unawaited(service.play('fonemas/fonema_m'));
      await player.playingStream.firstWhere((p) => p);
      focus.interrupt(begin: true, type: AudioInterruptionType.unknown);
      expect(player.playing, isFalse);
      focus.interrupt(begin: false, type: AudioInterruptionType.unknown);
      expect(player.playing, isFalse);

      await service.resume();
      expect(player.playing, isTrue);
      focus.unplugHeadphones();
      expect(player.playing, isFalse);
      focus.interrupt(begin: false, type: AudioInterruptionType.pause);
      expect(player.playing, isFalse);
      await service.stop();
    });
  });
}
