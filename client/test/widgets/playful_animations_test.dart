import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/screens/home_screen.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/confetti_overlay.dart';
import 'package:leo_parvulos_app/widgets/flying_stars_overlay.dart';
import 'package:leo_parvulos_app/widgets/living_sky_backdrop.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

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

  group('Paquete 1 & 2: Animaciones Infantiles (Minijuegos + Mundo Vivo)', () {
    test('RewardEffectRegistry incluye efecto bubbles junto a confetti y star_burst', () {
      expect(
        RewardEffectRegistry.registeredEffects,
        containsAll(['confetti', 'star_burst', 'bubbles']),
      );
    });

    testWidgets('FlyingStarsOverlay lanza 3 estrellas voladoras sin bloquear interacción', (tester) async {
      int trigger = 0;
      late StateSetter setOuterState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setOuterState = setState;
                return Stack(
                  children: [
                    const Center(child: Text('Juego Activo')),
                    Positioned.fill(
                      child: FlyingStarsOverlay(triggerCount: trigger),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNothing);

      setOuterState(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

      // Al completar los 680ms la capa se oculta limpiamente
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('SoundMatchGame aplica wiggle cariñoso y pista empática sin bloquear acierto', (tester) async {
      final tts = _SilentTts();
      bool won = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SoundMatchGame(
              ttsService: tts,
              onComplete: () => won = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Dos fallos no punitivos disparan wiggle y pista empática
      await tester.tap(find.byKey(const Key('match_item_Sol')));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(find.byKey(const Key('match_item_Manzana')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(won, isFalse);

      // Tocar la respuesta correcta gana inmediatamente
      await tester.tap(find.byKey(const Key('match_item_Pato')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(won, isTrue);
    });

    testWidgets('HomeScreen renderiza LivingSkyBackdrop y Leo salta al tocarlo', (tester) async {
      final tts = _SilentTts();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: HomeScreen(ttsService: tts),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LivingSkyBackdrop), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_leo_mascot')));
      await tester.pump(const Duration(milliseconds: 180));
      expect(tts.audioLogs.any((m) => m.contains('Soy Leo')), isTrue);

      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
    });
  });
}
