import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leo_parvulos_app/services/bundled_clip_player.dart';
import 'package:leo_parvulos_app/services/parent_settings_service.dart';
import 'package:leo_parvulos_app/services/speech_synthesizer.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/services/web_clip_backend.dart';
import 'package:leo_parvulos_app/widgets/admin_audio_inspector_banner.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

class _FakeClipPlayer implements ClipAudioPlayer {
  final Set<String> availableClips;
  final List<String> playedClips = [];
  int stopCalls = 0;

  _FakeClipPlayer(this.availableClips);

  @override
  Future<void> ensureInitialized() async {}

  @override
  bool hasClip(String clipId) => availableClips.contains(clipId);

  @override
  Future<bool> playClip(String clipId) async {
    if (!hasClip(clipId)) return false;
    playedClips.add(clipId);
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakeSpeechSynthesizer implements SpeechSynthesizer {
  final List<String> spokenTexts = [];
  int stopCalls = 0;

  @override
  Future<void> speak(
    String text, {
    String language = 'es-ES',
    double rate = 0.88,
  }) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  group('Sprint A Paso 2: Motor Híbrido de Audio Real (Grabación + Voz)', () {
    test('Prioridad 1: reproduce grabación humana cuando el clip existe en el manifiesto', () async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_m', 'fonemas/fonema_s'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      await audio.playClip(
        'fonemas/fonema_m',
        fallbackText: 'Traza la letra M',
      );

      expect(clipPlayer.playedClips, ['fonemas/fonema_m']);
      expect(synth.spokenTexts, isEmpty);
      expect(audio.audioLogs, ['Traza la letra M']);

      // Reproducir 2.ª y 3.ª vez consecutiva debe repetir siempre la grabación humana, nunca TTS
      await audio.playClip('fonemas/fonema_m', fallbackText: 'Traza la letra M');
      await audio.playClip('fonemas/fonema_m', fallbackText: 'Traza la letra M');
      expect(clipPlayer.playedClips, ['fonemas/fonema_m', 'fonemas/fonema_m', 'fonemas/fonema_m']);
      expect(synth.spokenTexts, isEmpty);
    });

    test('Prioridad 2: usa síntesis de voz en español cuando el fonema aún no tiene grabación', () async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_m'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      await audio.playClip(
        'fonemas/fonema_l',
        fallbackText: '¡Hola! Traza la letra L con tu dedito.',
      );

      expect(clipPlayer.playedClips, isEmpty);
      expect(synth.spokenTexts, ['¡Hola! Traza la letra L con tu dedito.']);
    });

    testWidgets('Botones de altavoz en LetterTracing y SoundMatchGame disparan el audio real', (tester) async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_s', 'fonemas/fonema_p'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(
        clipPlayer: clipPlayer,
        synthesizer: synth,
      );

      // 1. LetterTracing con botón de altavoz
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LetterTracing(
              letter: 's',
              audioKey: 'fonemas/fonema_s',
              ttsService: audio,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(clipPlayer.playedClips, ['fonemas/fonema_s']);

      await tester.tap(find.byKey(const Key('tracing_play_sound_btn')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(clipPlayer.playedClips, ['fonemas/fonema_s', 'fonemas/fonema_s']);

      // 2. SoundMatchGame con botón interactivo de fonema
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundMatchGame(
              targetLetter: 'P',
              targetPhoneme: '/p/',
              audioKey: 'fonemas/fonema_p',
              ttsService: audio,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(clipPlayer.playedClips.last, 'fonemas/fonema_p');

      await tester.tap(find.byKey(const Key('sound_match_play_btn')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(clipPlayer.playedClips.where((c) => c == 'fonemas/fonema_p').length, 2);
    });

    testWidgets('AdminAudioInspectorBanner diferencia voz grabada de voz sintética solo si está activo', (tester) async {
      ParentSettingsState.reset();
      ParvuloTtsService.lastPlayback.value = null;

      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_a'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(clipPlayer: clipPlayer, synthesizer: synth);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('App')),
                AdminAudioInspectorBanner(),
              ],
            ),
          ),
        ),
      );

      // Oculto por defecto para familias y niños
      expect(find.byKey(const Key('admin_audio_inspector_pill')), findsNothing);

      // Al activar modo admin aparece el indicador en vivo
      ParentSettingsState.adminAudioInspector = true;
      ParentSettingsState.revision.value++;
      await tester.pump();
      expect(find.byKey(const Key('admin_audio_inspector_pill')), findsOneWidget);

      // 1. Reproduce clip grabado -> muestra VOZ GRABADA
      await audio.playClip('fonemas/fonema_a', fallbackText: 'A');
      await tester.pump();
      expect(find.text('🎙️ VOZ GRABADA'), findsOneWidget);

      // 2. Reproduce clip faltante -> muestra VOZ SINTÉTICA + clip_id faltante
      await audio.playClip('silabas/silaba_bol', fallbackText: 'BOL');
      await tester.pump();
      expect(find.text('🤖 VOZ SINTÉTICA (Falta grabar)'), findsOneWidget);
      expect(find.textContaining('silabas/silaba_bol'), findsOneWidget);

      ParentSettingsState.reset();
    });

    test('Regresión letra M: navegar a otro fonema o a voz sintética SIEMPRE detiene el clip anterior y cancela cargas en vuelo', () async {
      final events = <String>[];
      final initCompleter = Completer<void>();
      var initPending = true;

      final clipPlayer = _SlowClipPlayer(
        availableClips: {'fonemas/fonema_m', 'fonemas/fonema_p'},
        onEvent: events.add,
        initGate: () async {
          if (initPending) {
            await initCompleter.future;
          }
        },
      );
      final synth = _RecordingSynth(events.add);
      final audio = ParvuloTtsService(clipPlayer: clipPlayer, synthesizer: synth);

      // 1. Usuario entra a Letra M mientras el manifiesto aún carga
      final pendingM = audio.playClip('fonemas/fonema_m', fallbackText: 'Traza M');
      await Future<void>.delayed(Duration.zero);

      // 2. Antes de que M termine de cargar, el usuario navega a Letra P
      initPending = false;
      initCompleter.complete();
      await audio.playClip('fonemas/fonema_p', fallbackText: 'Traza P');
      await pendingM;

      // M jamás debió reproducirse después de ser cancelada por P
      expect(events.where((e) => e == 'play:fonemas/fonema_m'), isEmpty);
      expect(events.where((e) => e == 'play:fonemas/fonema_p').length, 1);
      expect(ParvuloTtsService.lastPlayback.value?.clipId, 'fonemas/fonema_p');

      // 3. Usuario navega a una letra sin grabación (L) -> debe llamar stop() en clipPlayer ANTES de hablar
      events.clear();
      await audio.playClip('fonemas/fonema_l', fallbackText: 'Traza L');
      expect(events.first, 'clip_stop');
      expect(events, contains('tts:Traza L'));
      expect(events.where((e) => e.startsWith('play:')), isEmpty);
    });

    test('WebClipBackend: cada clip cambia de URL limpia y jamás repite fonema_m al pasar a otra letra o repetir', () async {
      final fakeWeb = _FakeWebClipBackend();
      const manifestJson = '''
{
  "schema": 1,
  "version": 1,
  "manifest_hash": "hash1",
  "clip_count": 3,
  "clips": {
    "fonemas/fonema_m": {
      "category": "fonemas",
      "name": "fonema_m",
      "files": {
        "aac": {"path": "fonemas/fonema_m.m4a", "bytes": 100, "sha256": "sha_m"}
      }
    },
    "fonemas/fonema_p": {
      "category": "fonemas",
      "name": "fonema_p",
      "files": {
        "aac": {"path": "fonemas/fonema_p.m4a", "bytes": 100, "sha256": "sha_p"}
      }
    },
    "palabras/palabra_arbol": {
      "category": "palabras",
      "name": "palabra_arbol",
      "files": {
        "aac": {"path": "palabras/palabra_arbol.m4a", "bytes": 100, "sha256": "sha_arbol"}
      }
    }
  }
}
''';

      final mockHttp = MockClient((req) async {
        expect(req.url.path, '/api/audio/manifest');
        return http.Response(manifestJson, 200);
      });

      final player = BundledClipAudioPlayer(
        bundle: _EmptyAssetBundle(),
        webBackend: fakeWeb,
        httpClient: mockHttp,
        apiBaseUrl: 'http://127.0.0.1:8000',
      );

      expect(await player.playClip('fonemas/fonema_m'), isTrue);
      expect(await player.playClip('fonemas/fonema_p'), isTrue);
      expect(await player.playClip('palabras/arbol'), isTrue);
      expect(await player.playClip('palabras/arbol'), isTrue);
      await player.stop();

      expect(fakeWeb.playedUrls, [
        'http://127.0.0.1:8000/api/audio/v1/fonemas/fonema_m.m4a?sha256=sha_m',
        'http://127.0.0.1:8000/api/audio/v1/fonemas/fonema_p.m4a?sha256=sha_p',
        'http://127.0.0.1:8000/api/audio/v1/palabras/palabra_arbol.m4a?sha256=sha_arbol',
        'http://127.0.0.1:8000/api/audio/v1/palabras/palabra_arbol.m4a?sha256=sha_arbol',
      ]);
      expect(fakeWeb.stopCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('Al salir de LetterTracing (dispose), el audio activo se detiene de inmediato', (tester) async {
      final clipPlayer = _FakeClipPlayer({'fonemas/fonema_m'});
      final synth = _FakeSpeechSynthesizer();
      final audio = ParvuloTtsService(clipPlayer: clipPlayer, synthesizer: synth);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LetterTracing(
              letter: 'm',
              audioKey: 'fonemas/fonema_m',
              ttsService: audio,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final stopsBeforeLeave = clipPlayer.stopCalls;

      // Simula salir de la pantalla de letra M hacia otra vista
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Mapa'))),
      );
      await tester.pump();

      expect(clipPlayer.stopCalls, greaterThan(stopsBeforeLeave));
    });
  });
}

class _SlowClipPlayer implements ClipAudioPlayer {
  final Set<String> availableClips;
  final void Function(String event) onEvent;
  final Future<void> Function() initGate;

  _SlowClipPlayer({
    required this.availableClips,
    required this.onEvent,
    required this.initGate,
  });

  @override
  Future<void> ensureInitialized() => initGate();

  @override
  bool hasClip(String clipId) => availableClips.contains(clipId);

  @override
  Future<bool> playClip(String clipId) async {
    if (!hasClip(clipId)) return false;
    onEvent('play:$clipId');
    return true;
  }

  @override
  Future<void> stop() async {
    onEvent('clip_stop');
  }
}

class _RecordingSynth implements SpeechSynthesizer {
  final void Function(String event) onEvent;
  _RecordingSynth(this.onEvent);

  @override
  Future<void> speak(String text, {String language = 'es-ES', double rate = 0.88}) async {
    onEvent('tts:$text');
  }

  @override
  Future<void> stop() async {
    onEvent('tts_stop');
  }
}

class _FakeWebClipBackend implements WebClipBackend {
  final List<String> playedUrls = [];
  int stopCalls = 0;

  @override
  Future<WebClipPlayStatus> playUrl(String url) async {
    playedUrls.add(url);
    return WebClipPlayStatus.played;
  }

  @override
  void stop() {
    stopCalls++;
  }
}

class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      throw FlutterError('No bundled manifest in test');
}
