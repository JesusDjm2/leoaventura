import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/animated_leo.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';

class _SilentTts implements TtsService {
  final List<String> logs = [];

  @override
  List<String> get audioLogs => logs;

  @override
  void clearLogs() => logs.clear();

  @override
  Future<void> speak(String text) async => logs.add(text);
}

void main() {
  group('Integración Rive: <AnimatedLeo /> y State Machine', () {
    testWidgets('asset leo_mascot.riv está empaquetado con cabecera binaria RIVE válida', (tester) async {
      final bytes = (await tester.runAsync(
        () => rootBundle.load('assets/animations/leo_mascot.riv'),
      ))!;

      expect(bytes.lengthInBytes, greaterThan(10000));
      final magic = String.fromCharCodes(bytes.buffer.asUint8List(0, 4));
      expect(magic, 'RIVE');
    });

    testWidgets('al cambiar state de "idle" a "happy" y "sad", el controlador de Rive dispara la animación correcta', (tester) async {
      LeoRiveStateDriver? capturedDriver;
      late StateSetter updateState;
      String leoState = 'idle';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateState = setState;
                return Center(
                  child: AnimatedLeo(
                    state: leoState,
                    size: 140,
                    showMoodBadge: true,
                    onStateMachineReady: (driver) => capturedDriver = driver,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Estado inicial: idle
      expect(capturedDriver, isNotNull);
      expect(capturedDriver!.isRiveNativeActive, isTrue);
      expect(capturedDriver!.activeState, 'idle');
      expect(capturedDriver!.numericStateValue, 0.0);
      expect(capturedDriver!.isHappy, isFalse);
      expect(capturedDriver!.isSad, isFalse);

      // 2. Transición: idle -> happy
      updateState(() => leoState = 'happy');
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedDriver!.activeState, 'happy');
      expect(capturedDriver!.numericStateValue, 1.0);
      expect(capturedDriver!.isHappy, isTrue);
      expect(capturedDriver!.isSad, isFalse);
      expect(find.text('¡Muy bien!'), findsOneWidget);

      // 3. Transición: happy -> sad (empático, nunca punitivo)
      updateState(() => leoState = 'sad');
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedDriver!.activeState, 'sad');
      expect(capturedDriver!.numericStateValue, 2.0);
      expect(capturedDriver!.isHappy, isFalse);
      expect(capturedDriver!.isSad, isTrue);
      expect(find.text('¡Casi! Tú puedes'), findsOneWidget);
      expect(capturedDriver!.appliedTransitions, ['idle', 'happy', 'sad']);
    });

    testWidgets('conectado a SoundMatchGame: acierto -> "happy", fallo -> "sad" empático', (tester) async {
      final tts = _SilentTts();
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundMatchGame(
              targetLetter: 'P',
              targetPhoneme: '/p/ /p/',
              ttsService: tts,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 50));

      final leoFinder = find.byKey(const Key('sound_match_animated_leo'));
      expect(leoFinder, findsOneWidget);
      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'idle');

      // 1. El niño toca una opción incorrecta ("Sol") -> estado empático "sad"
      await tester.tap(find.byKey(const Key('match_item_Sol')));
      await tester.pump(const Duration(milliseconds: 60));

      expect(completed, isFalse);
      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'sad');
      final leoStateObj = tester.state<AnimatedLeoState>(leoFinder);
      expect(leoStateObj.riveDriver?.numericStateValue, 2.0);
      expect(leoStateObj.riveDriver?.isSad, isTrue);
      expect(find.text('¡Casi! Tú puedes'), findsOneWidget);

      // 2. El niño acierta tocando "Pato" -> estado celebratorio "happy"
      await tester.tap(find.byKey(const Key('match_item_Pato')));
      await tester.pump(const Duration(milliseconds: 60));

      expect(completed, isTrue);
      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'happy');
      expect(leoStateObj.riveDriver?.numericStateValue, 1.0);
      expect(leoStateObj.riveDriver?.isHappy, isTrue);
      expect(find.text('¡Muy bien!'), findsOneWidget);
    });

    testWidgets('conectado a LetterTracing: trazo incompleto -> "sad" empático, trazo completo -> "happy"', (tester) async {
      final tts = _SilentTts();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LetterTracing(letter: 'm', ttsService: tts),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 50));

      final leoFinder = find.byKey(const Key('tracing_animated_leo'));
      expect(leoFinder, findsOneWidget);
      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'idle');

      // Trazo corto incompleto -> estado empático "sad"
      final canvasRect = tester.getRect(find.byKey(const Key('tracing_canvas_gesture')));
      final shortGesture = await tester.startGesture(canvasRect.topLeft + const Offset(10, 10));
      await shortGesture.moveTo(canvasRect.topLeft + const Offset(20, 20));
      await shortGesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'sad');

      // Trazo completo sobre los checkpoints de M -> estado "happy"
      final points = LetterTracing.defaultCheckpointsByLetter['m']!
          .map((p) => Offset(
                canvasRect.left + p.dx * canvasRect.width,
                canvasRect.top + p.dy * canvasRect.height,
              ))
          .toList();
      final fullGesture = await tester.startGesture(points.first);
      for (final pt in points.skip(1)) {
        await fullGesture.moveTo(pt);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await fullGesture.up();
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.widget<AnimatedLeo>(leoFinder).state, 'happy');
    });

    testWidgets('rendimiento 60fps: 60 frames consecutivos con transiciones Rive sin jank (< 16.67ms promedio)', (tester) async {
      late StateSetter updateState;
      String leoState = 'idle';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateState = setState;
                return Center(child: AnimatedLeo(state: leoState, size: 120));
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 50));

      // Warm-up de 5 frames
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(microseconds: 16667));
      }

      // Medición de 60 frames simulando 1 segundo completo a 60fps
      final stopwatch = Stopwatch()..start();
      for (int frame = 0; frame < 60; frame++) {
        if (frame == 20) updateState(() => leoState = 'happy');
        if (frame == 40) updateState(() => leoState = 'sad');
        if (frame == 55) updateState(() => leoState = 'idle');
        await tester.pump(const Duration(microseconds: 16667));
      }
      stopwatch.stop();

      final avgMsPerFrame = stopwatch.elapsedMicroseconds / 1000.0 / 60.0;
      expect(
        avgMsPerFrame,
        lessThan(16.67),
        reason: 'Promedio por frame demasiado alto: ${avgMsPerFrame.toStringAsFixed(2)}ms',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
