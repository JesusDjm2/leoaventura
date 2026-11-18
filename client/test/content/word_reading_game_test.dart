import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/content/content_engine.dart';
import 'package:leo_parvulos_app/main.dart';
import 'package:leo_parvulos_app/services/session_sync_service.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/word_reading_game.dart';

class _RecordingTts implements TtsService {
  final List<String> _logs = [];
  @override
  List<String> get audioLogs => List.unmodifiable(_logs);
  @override
  Future<void> speak(String text) async => _logs.add(text);
  @override
  void clearLogs() => _logs.clear();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    AppSessionState.reset();
  });

  group('Bloque 1 & 2: 4.º Minijuego Lectura de Palabras y 20 Trazos Refinados', () {
    test('Los 20 fonemas tienen checkpoints pedagógicos dedicados (ninguno usa fallback genérico)', () {
      for (final level in DefaultCurriculumCatalog.levels) {
        final letter = level.letter.toLowerCase();
        expect(
          LetterTracing.defaultCheckpointsByLetter.containsKey(letter),
          isTrue,
          reason: 'La letra "$letter" debe tener checkpoints pedagógicos propios',
        );
        expect(
          LetterTracing.defaultCheckpointsByLetter[letter]!.length,
          greaterThanOrEqualTo(4),
        );
      }
    });

    testWidgets('WordReadingGame permite decodificar sílabas (MA + MÁ) y completar comprensión lectora',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final tts = _RecordingTts();
      final levelM = DefaultCurriculumCatalog.levelForLetter('m');
      // Consonante M tiene 4 pasos: Trazar (0), Sonido (1), Sílabas (2), Leer (3)
      expect(levelM.activities.length, 4);
      expect(levelM.activities[3].type, ActivityTypes.wordReading);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: TracingGameScreen(level: levelM, ttsService: tts),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Ir al paso 4: Leer
      await tester.tap(find.byKey(const Key('activity_step_3')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WordReadingGame), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
      expect(find.text('MÁ'), findsOneWidget);

      // Tocar ambas sílabas para decodificar la palabra
      await tester.tap(find.byKey(const Key('word_syllable_0')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('word_syllable_1')));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tts.audioLogs.any((m) => m.contains('Mamá')), isTrue);

      // Elegir la ilustración correcta ("Mamá")
      await tester.ensureVisible(find.byKey(const Key('word_option_Mamá')));
      await tester.tap(find.byKey(const Key('word_option_Mamá')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('¡Ya sabes leer!'), findsOneWidget);
      expect(AppSessionState.isActivityCompleted('act_m_word_reading'), isTrue);
    });
  });
}
