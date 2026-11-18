import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/services/haptic_service.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/confetti_overlay.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/primary_button.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

class _MockHapticController implements HapticController {
  int lightImpactCalls = 0;
  int mediumImpactCalls = 0;
  int selectionClickCalls = 0;

  @override
  Future<void> lightImpact() async {
    lightImpactCalls++;
  }

  @override
  Future<void> mediumImpact() async {
    mediumImpactCalls++;
  }

  @override
  Future<void> selectionClick() async {
    selectionClickCalls++;
  }
}

class _SilentTts implements TtsService {
  @override
  List<String> get audioLogs => const [];

  @override
  void clearLogs() {}

  @override
  Future<void> speak(String text) async {}
}

void main() {
  late _MockHapticController mockHaptics;

  setUp(() {
    mockHaptics = _MockHapticController();
    HapticService.instance = mockHaptics;
  });

  tearDown(() {
    HapticService.reset();
  });

  group('Partículas Flame (ConfettiOverlay) + Háptica Integrada', () {
    testWidgets('1. Al tocar PrimaryButton se dispara HapticFeedback.lightImpact', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '¡Jugar!',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(pressed, isTrue);
      expect(mockHaptics.lightImpactCalls, greaterThanOrEqualTo(1));
      expect(mockHaptics.mediumImpactCalls, 0);
    });

    testWidgets('2. Éxito en SoundMatchGame inicializa partículas Flame y llama HapticFeedback.mediumImpact', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundMatchGame(
              targetLetter: 'P',
              targetPhoneme: '/p/ /p/',
              ttsService: _SilentTts(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Antes de ganar: ConfettiOverlay inactivo (0% CPU, sin GameWidget montado)
      expect(find.byKey(const Key('flame_confetti_game_widget')), findsNothing);
      expect(mockHaptics.mediumImpactCalls, 0);

      // Simular acierto tocando "Pato"
      await tester.tap(find.byKey(const Key('match_item_Pato')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verifica controlador háptico (lightImpact al tocar + mediumImpact al ganar)
      expect(mockHaptics.lightImpactCalls, greaterThanOrEqualTo(1));
      expect(mockHaptics.mediumImpactCalls, 1);

      // Verifica inicialización real del sistema de partículas Flame
      expect(find.byKey(const Key('flame_confetti_game_widget')), findsOneWidget);
      final overlayState = tester.state<ConfettiOverlayState>(
        find.byKey(const Key('sound_match_confetti_overlay')),
      );
      expect(overlayState.game, isNotNull);
      expect(overlayState.game!.isInitialized, isTrue);
      expect(overlayState.game!.burstCount, greaterThanOrEqualTo(1));
      expect(overlayState.game!.activeParticleSystems, greaterThanOrEqualTo(1));
    });

    testWidgets('3. Éxito en LetterTracing dispara ConfettiOverlay (Flame) y HapticFeedback.mediumImpact', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LetterTracing(
              letter: 'm',
              ttsService: _SilentTts(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('flame_confetti_game_widget')), findsNothing);

      final rect = tester.getRect(find.byKey(const Key('tracing_canvas_gesture')));
      final points = LetterTracing.defaultCheckpointsByLetter['m']!
          .map((p) => Offset(rect.left + p.dx * rect.width, rect.top + p.dy * rect.height))
          .toList();

      final gesture = await tester.startGesture(points.first);
      for (final pt in points.skip(1)) {
        await gesture.moveTo(pt);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      expect(mockHaptics.mediumImpactCalls, 1);
      expect(find.byKey(const Key('flame_confetti_game_widget')), findsOneWidget);

      final overlayState = tester.state<ConfettiOverlayState>(
        find.byKey(const Key('tracing_confetti_overlay')),
      );
      expect(overlayState.game, isNotNull);
      expect(overlayState.game!.isInitialized, isTrue);
      expect(overlayState.game!.burstCount, 1);
    });

    testWidgets('4. Uso intensivo de partículas mantiene presupuesto CPU < 15% (< 2.5ms/frame) y libera memoria', (tester) async {
      ConfettiFlameGame? capturedGame;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(),
                ConfettiOverlay(
                  active: true,
                  particleCount: 60,
                  onGameCreated: (g) => capturedGame = g,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final game = capturedGame!;
      expect(game.isInitialized, isTrue);

      // Disparar 5 ráfagas intensivas seguidas (el tope concurrente es 3)
      for (int i = 0; i < 5; i++) {
        game.emitBurst();
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(game.activeParticleSystems, lessThanOrEqualTo(ConfettiFlameGame.maxConcurrentSystems));

      // Medir 90 pasos del motor Flame a 60fps (1.5 segundos simulados)
      final stopwatch = Stopwatch()..start();
      for (int frame = 0; frame < 90; frame++) {
        game.updateTree(1 / 60);
        game.processLifecycleEvents();
      }
      stopwatch.stop();

      final avgMsPerFrame = stopwatch.elapsedMicroseconds / 1000.0 / 90.0;
      // 15% de un frame de 16.67ms (60fps) = 2.50ms
      expect(
        avgMsPerFrame,
        lessThan(2.5),
        reason: 'Costo CPU promedio por frame excede el 15% del presupuesto 60fps: ${avgMsPerFrame.toStringAsFixed(3)}ms',
      );

      // Avanzar más allá del lifespan (1.6s) para confirmar limpieza automática sin fugas
      for (int i = 0; i < 40; i++) {
        game.updateTree(1 / 60);
        game.processLifecycleEvents();
      }
      expect(game.activeParticleSystems, 0);
    });

    testWidgets('5. RewardEffectRegistry permite añadir nuevos efectos visuales sin tocar el núcleo', (tester) async {
      RewardEffectRegistry.register(
        'rainbow_bubbles',
        (origin, count, random) => Particle.generate(
          count: count,
          lifespan: 1.0,
          generator: (_) => CircleParticle(
            radius: 6,
            paint: Paint()..color = const Color(0xFF32BCE4),
          ),
        ),
      );

      expect(RewardEffectRegistry.registeredEffects, contains('rainbow_bubbles'));

      ConfettiFlameGame? capturedGame;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(),
                ConfettiOverlay(
                  active: true,
                  effectName: 'rainbow_bubbles',
                  particleCount: 16,
                  onGameCreated: (g) => capturedGame = g,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      expect(capturedGame, isNotNull);
      expect(capturedGame!.burstCount, 1);
      expect(capturedGame!.activeParticleSystems, 1);
    });
  });
}
