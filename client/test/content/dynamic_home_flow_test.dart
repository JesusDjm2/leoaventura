import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/content/content_engine.dart';
import 'package:leo_parvulos_app/main.dart';
import 'package:leo_parvulos_app/screens/home_screen.dart';
import 'package:leo_parvulos_app/services/session_sync_service.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';
import 'package:leo_parvulos_app/widgets/syllable_builder_game.dart';

class _SilentTts implements TtsService {
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

  group('Sprint A Paso 1: Mapa Dinámico de 20 Fonemas y 3 Minijuegos', () {
    testWidgets('HomeScreen expone los 20 fonemas y filtra por unidad pedagógica', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 550));

      expect(find.byKey(const Key('curriculum_map_section')), findsOneWidget);
      expect(find.text('Todas (20)'), findsOneWidget);

      // Filtrar por Unidad 1 (Vocales = 5: a, e, i, o, u)
      await tester.ensureVisible(find.byKey(const Key('unit_filter_1')));
      await tester.tap(find.byKey(const Key('unit_filter_1')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('curriculum_card_a')), findsOneWidget);
      expect(find.byKey(const Key('curriculum_card_u')), findsOneWidget);
      expect(find.byKey(const Key('curriculum_card_s')), findsNothing);

      // Filtrar por Unidad 2 (Consonantes 1 = m, p, s, l, t)
      await tester.tap(find.byKey(const Key('unit_filter_2')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('curriculum_card_s')), findsOneWidget);
      expect(find.byKey(const Key('curriculum_card_l')), findsOneWidget);
    });

    testWidgets('Tocar la letra S abre Trazado, Sonido y Sílabas dinámicas de la S', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final tts = _SilentTts();
      final levelS = DefaultCurriculumCatalog.levelForLetter('s');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: TracingGameScreen(level: levelS, ttsService: tts),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Paso 1: Trazado de S
      expect(find.text('Letra S · Sol'), findsOneWidget);
      expect(find.byType(LetterTracing), findsOneWidget);
      final tracingWidget = tester.widget<LetterTracing>(find.byType(LetterTracing));
      expect(tracingWidget.letter.toLowerCase(), 's');

      // Paso 2: Emparejar Sonido /s/
      await tester.tap(find.byKey(const Key('activity_step_1')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SoundMatchGame), findsOneWidget);
      expect(find.text('Sol'), findsOneWidget);

      // Paso 3: Constructor de Sílabas con S (S + A = SA)
      await tester.tap(find.byKey(const Key('activity_step_2')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SyllableBuilderGame), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('vowel_btn_A')));
      await tester.tap(find.byKey(const Key('vowel_btn_A')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SA'), findsOneWidget);
      expect(find.text('¡Has formado SA!'), findsOneWidget);
      expect(AppSessionState.isActivityCompleted('act_s_syllable_builder'), isTrue);
    });
  });
}
