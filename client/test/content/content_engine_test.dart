import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leo_parvulos_app/content/content_engine.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

class _RecordingTtsService implements TtsService {
  final List<String> spoken = [];

  @override
  List<String> get audioLogs => List.unmodifiable(spoken);

  @override
  void clearLogs() => spoken.clear();

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

/// Fixture que replica exactamente el contrato JSON de `GET /api/curriculum/levels`.
Map<String, dynamic> _sampleBackendResponseJson() => {
      'version': '1.0',
      'total_phonemes': 2,
      'levels': [
        {
          'id': 8,
          'code': 'phoneme_s',
          'title': 'Fonema /s/ - Sol',
          'phoneme': '/s/',
          'letter': 's',
          'example_word': 'Sol',
          'unit': 2,
          'order_index': 8,
          'audio_key': 'fonemas/fonema_s',
          'activities': [
            {
              'id': 15,
              'activity_code': 'act_s_tracing',
              'type': 'tracing',
              'title': 'Traza la letra S',
              'instruction': '¡Hola! Traza la letra S con tu dedito.',
              'audio_key': 'fonemas/fonema_s',
              'order_index': 1,
              'payload': {
                'letter': 's',
                'phoneme': '/s/',
                'example_word': 'Sol',
                'audio_key': 'fonemas/fonema_s',
                'instruction_audio': 'instrucciones/instruccion_traza_letra_s',
                'success_text': '¡Excelente! Has trazado la letra S. ¡Sss como en Sol!',
                'checkpoints': [
                  {'x': 0.64, 'y': 0.30},
                  {'x': 0.48, 'y': 0.26},
                  {'x': 0.34, 'y': 0.38},
                  {'x': 0.50, 'y': 0.50},
                  {'x': 0.66, 'y': 0.62},
                  {'x': 0.50, 'y': 0.74},
                  {'x': 0.34, 'y': 0.70},
                ],
              },
            },
            {
              'id': 16,
              'activity_code': 'act_s_sound_match',
              'type': 'sound_match',
              'title': 'Encuentra el sonido /s/',
              'instruction': 'Toca el dibujo que empieza con /s/.',
              'audio_key': 'fonemas/fonema_s',
              'order_index': 2,
              'payload': {
                'target_letter': 'S',
                'target_phoneme': '/s/',
                'audio_key': 'fonemas/fonema_s',
                'options': [
                  {
                    'name': 'Sol',
                    'image_key': 'palabras/s_sol',
                    'emoji': '🌞',
                    'is_correct': true,
                    'feedback_text': '¡Sol! Empieza con /s/.',
                    'audio_key': 'palabras/sol',
                  },
                  {
                    'name': 'Pato',
                    'image_key': 'palabras/p_pato',
                    'emoji': '🦆',
                    'is_correct': false,
                    'feedback_text': 'Pato empieza con /p/.',
                    'audio_key': 'palabras/pato',
                  },
                  {
                    'name': 'Mamá',
                    'image_key': 'palabras/m_mama',
                    'emoji': '👩',
                    'is_correct': false,
                    'feedback_text': 'Mamá empieza con /m/.',
                    'audio_key': 'palabras/mama',
                  },
                ],
              },
            },
          ],
        },
        {
          'id': 6,
          'code': 'phoneme_m',
          'title': 'Fonema /m/ - Mamá',
          'phoneme': '/m/',
          'letter': 'm',
          'example_word': 'Mamá',
          'unit': 2,
          'order_index': 6,
          'audio_key': 'fonemas/fonema_m',
          'activities': [
            {
              'id': 11,
              'activity_code': 'act_m_tracing',
              'type': 'tracing',
              'title': 'Traza la letra M',
              'instruction': '¡Hola! Traza la letra M con tu dedito.',
              'audio_key': 'fonemas/fonema_m',
              'order_index': 1,
              'payload': {
                'letter': 'm',
                'phoneme': '/m/',
                'example_word': 'Mamá',
                'audio_key': 'fonemas/fonema_m',
                'checkpoints': [
                  [0.22, 0.35],
                  [0.50, 0.55],
                  [0.78, 0.75],
                ],
              },
            },
          ],
        },
      ],
    };

void main() {
  group('Fase 16: Parseo de JSON del backend a ActivityModel y CurriculumResponse', () {
    test('parsea correctamente el JSON de /api/curriculum/levels incluyendo trazado y emparejamiento', () {
      final response = CurriculumResponse.fromJson(_sampleBackendResponseJson());

      expect(response.version, '1.0');
      expect(response.totalPhonemes, 2);
      expect(response.levels, hasLength(2));

      final levelS = response.levels.first;
      expect(levelS.code, 'phoneme_s');
      expect(levelS.letter, 's');
      expect(levelS.phoneme, '/s/');
      expect(levelS.exampleWord, 'Sol');
      expect(levelS.activities, hasLength(2));

      // Actividad 1: Trazado
      final tracing = levelS.activities[0];
      expect(tracing.isTracing, isTrue);
      expect(tracing.isSoundMatch, isFalse);
      expect(tracing.activityCode, 'act_s_tracing');
      expect(tracing.audioKey, 'fonemas/fonema_s');

      final tracingPayload = tracing.tracingPayload;
      expect(tracingPayload.letter, 's');
      expect(tracingPayload.phoneme, '/s/');
      expect(tracingPayload.exampleWord, 'Sol');
      expect(tracingPayload.audioKey, 'fonemas/fonema_s');
      expect(tracingPayload.checkpoints, hasLength(7));
      expect(tracingPayload.checkpoints.first, const Offset(0.64, 0.30));

      // Actividad 2: Emparejamiento de fonema con imagen
      final soundMatch = levelS.activities[1];
      expect(soundMatch.isSoundMatch, isTrue);
      expect(soundMatch.isTracing, isFalse);

      final matchPayload = soundMatch.soundMatchPayload;
      expect(matchPayload.targetLetter, 'S');
      expect(matchPayload.targetPhoneme, '/s/');
      expect(matchPayload.options, hasLength(3));
      expect(matchPayload.options.first.name, 'Sol');
      expect(matchPayload.options.first.isCorrect, isTrue);
      expect(matchPayload.options[1].isCorrect, isFalse);

      // Actividad en formato compacto de checkpoints [[x, y], ...]
      final levelMTracing = response.levels[1].activities.first.tracingPayload;
      expect(levelMTracing.letter, 'm');
      expect(levelMTracing.checkpoints, hasLength(3));
      expect(levelMTracing.checkpoints[1], const Offset(0.50, 0.55));
    });

    test('CurriculumService consume GET /api/curriculum/levels y almacena en caché', () async {
      int httpCalls = 0;
      final mockClient = MockClient((request) async {
        httpCalls++;
        expect(request.method, 'GET');
        expect(request.url.path, '/api/curriculum/levels');
        return http.Response(
          jsonEncode(_sampleBackendResponseJson()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = CurriculumService(
        baseUri: Uri.parse('https://api.leoparvulos.test'),
        client: mockClient,
      );

      final first = await service.fetchLevels();
      expect(first.levels, hasLength(2));
      expect(httpCalls, 1);

      // Segunda llamada usa caché sin repetir petición de red
      final second = await service.fetchLevels();
      expect(second.levels.first.letter, 's');
      expect(httpCalls, 1);

      // forceRefresh consulta nuevamente el endpoint
      await service.fetchLevels(forceRefresh: true);
      expect(httpCalls, 2);
    });
  });

  group('Fase 16: Renderizado dinámico desde JSON', () {
    testWidgets('inyecta JSON con letra "s" y verifica que LetterTracing renderiza una "s" con audio dinámico', (tester) async {
      final tts = _RecordingTtsService();
      bool completed = false;

      final tracingJsonS = ((_sampleBackendResponseJson()['levels'] as List).first['activities'] as List).first
          as Map<String, dynamic>;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicActivityHost.fromJson(
              tracingJsonS,
              ttsService: tts,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Verifica que se montó LetterTracing con parámetros recibidos desde JSON
      final tracingWidget = tester.widget<LetterTracing>(find.byType(LetterTracing));
      expect(tracingWidget.letter, 's');
      expect(tracingWidget.audioKey, 'fonemas/fonema_s');
      expect(tracingWidget.exampleWord, 'Sol');

      // 2. Verifica texto visible en cabecera para la letra "S"
      expect(find.text('Traza la letra "S"'), findsOneWidget);

      // 3. Verifica que el CustomPaint renderiza exactamente la letra guía "s"
      final customPaintFinder = find.byKey(const Key('tracing_guide_canvas_s'));
      expect(customPaintFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as LetterTracingPainter;
      expect(painter.letter, 's');
      expect(painter.checkpoints, hasLength(7));

      // 4. Verifica que la locución inicial recibió la instrucción de la letra S (sin hardcodeo de M)
      expect(tts.spoken, isNotEmpty);
      expect(tts.spoken.first, contains('letra S'));

      // 5. Traza a lo largo de los checkpoints de "s" y verifica finalización + audio dinámico de Sol
      final gestureRect = tester.getRect(find.byKey(const Key('tracing_canvas_gesture')));
      final sPoints = tracingWidget.resolvedCheckpoints
          .map((p) => Offset(
                gestureRect.left + p.dx * gestureRect.width,
                gestureRect.top + p.dy * gestureRect.height,
              ))
          .toList();

      final gesture = await tester.startGesture(sPoints.first);
      for (final point in sPoints.skip(1)) {
        await gesture.moveTo(point);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(completed, isTrue);
      expect(find.byKey(const Key('celebration_overlay')), findsOneWidget);
      expect(tts.spoken.last, contains('Sol'));
      expect(tts.spoken.last, isNot(contains('Mamá')));
    });

    testWidgets('inyecta JSON de tipo sound_match y resuelve dinámicamente SoundMatchGame', (tester) async {
      final tts = _RecordingTtsService();
      bool completed = false;

      final soundMatchJsonS = ((_sampleBackendResponseJson()['levels'] as List).first['activities'] as List)[1]
          as Map<String, dynamic>;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicActivityHost.fromJson(
              soundMatchJsonS,
              ttsService: tts,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SoundMatchGame), findsOneWidget);
      expect(find.text('Busca el fonema S (/s/)'), findsOneWidget);
      expect(find.byKey(const Key('match_item_Sol')), findsOneWidget);

      await tester.tap(find.byKey(const Key('match_item_Sol')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(completed, isTrue);
      expect(tts.spoken.last, contains('¡Sol!'));
    });

    testWidgets('ActivityRegistry permite registrar un nuevo tipo de minijuego sin tocar el núcleo', (tester) async {
      final registry = ActivityRegistry.withDefaults();
      registry.register(
        'syllable_flashcard',
        (context, activity, {ttsService, onComplete}) => Center(
          child: Text('Flashcard dinámica: ${activity.payload['syllable']}'),
        ),
      );

      final customJson = {
        'id': 99,
        'activity_code': 'act_sa_flashcard',
        'type': 'syllable_flashcard',
        'title': 'Sílaba SA',
        'instruction': 'Lee la sílaba SA',
        'audio_key': 'silabas/sa',
        'order_index': 3,
        'payload': {'syllable': 'sa'},
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicActivityHost.fromJson(customJson, registry: registry),
          ),
        ),
      );

      expect(find.text('Flashcard dinámica: sa'), findsOneWidget);
    });
  });
}
