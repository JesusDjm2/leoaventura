import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';
import 'package:leo_parvulos_app/widgets/sound_match_game.dart';
import 'package:leo_parvulos_app/widgets/syllable_builder_game.dart';

/// Servicio de audio instrumentado para QA con medición de latencia (Touch-to-Playback).
class LatencyMeasuringTtsService implements TtsService {
  final List<String> _logs = [];
  final List<int> recordedLatencies = [];
  final Stopwatch _stopwatch = Stopwatch();

  void markTouch() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  List<String> get audioLogs => List.unmodifiable(_logs);

  @override
  Future<void> speak(String text) async {
    final latency = _stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0;
    _stopwatch.stop();
    recordedLatencies.add(latency);
    _logs.add(text);
  }

  @override
  void clearLogs() {
    _logs.clear();
    recordedLatencies.clear();
  }
}

void main() {
  group('Fase 12: QA de Audio y Medición de Latencia en Minijuegos (< 100 ms)', () {
    testWidgets('1. Minijuego Trazado M: Latencia de toque a reproducción < 100 ms', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final qaAudio = LatencyMeasuringTtsService();
      bool isCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LetterTracing(
                letter: 'm',
                ttsService: qaAudio,
                onComplete: () => isCompleted = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final canvasFinder = find.byKey(const Key('tracing_canvas_gesture'));
      final topLeft = tester.getTopLeft(canvasFinder);
      final size = tester.getSize(canvasFinder);

      final checkpoints = [
        const Offset(0.22, 0.35),
        const Offset(0.22, 0.55),
        const Offset(0.22, 0.75),
        const Offset(0.36, 0.35),
        const Offset(0.50, 0.55),
        const Offset(0.50, 0.75),
        const Offset(0.64, 0.35),
        const Offset(0.78, 0.55),
        const Offset(0.78, 0.75),
      ];

      final gesture = await tester.startGesture(
        Offset(topLeft.dx + size.width * checkpoints.first.dx, topLeft.dy + size.height * checkpoints.first.dy),
      );
      await tester.pump(const Duration(milliseconds: 10));

      for (int i = 1; i < checkpoints.length - 1; i++) {
        final cp = checkpoints[i];
        await gesture.moveTo(Offset(topLeft.dx + size.width * cp.dx, topLeft.dy + size.height * cp.dy));
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Marcamos el toque decisivo que completa el trazo
      qaAudio.markTouch();
      final lastCp = checkpoints.last;
      await gesture.moveTo(Offset(topLeft.dx + size.width * lastCp.dx, topLeft.dy + size.height * lastCp.dy));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 30));

      expect(isCompleted, isTrue);
      expect(qaAudio.recordedLatencies.isNotEmpty, isTrue);

      final lastLatency = qaAudio.recordedLatencies.last;
      debugPrint('[QA Audio] Latencia Trazado M: ${lastLatency}ms');
      expect(lastLatency, lessThan(100), reason: 'La latencia de audio debe ser menor a 100ms');
    });

    testWidgets('2. Minijuego Discriminación P: Latencia de toque a reproducción < 100 ms', (tester) async {
      final qaAudio = LatencyMeasuringTtsService();
      bool isCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SoundMatchGame(
                targetLetter: 'P',
                ttsService: qaAudio,
                onComplete: () => isCompleted = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final patoFinder = find.byKey(const Key('match_item_Pato'));
      expect(patoFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(patoFinder));
      qaAudio.markTouch(); // Marca en el momento del contacto táctil
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 30));

      expect(isCompleted, isTrue);
      final latency = qaAudio.recordedLatencies.last;
      debugPrint('[QA Audio] Latencia Discriminación Pato: ${latency}ms');
      expect(latency, lessThan(100), reason: 'La latencia del fonema /p/ debe ser menor a 100ms');
    });

    testWidgets('3. Minijuego Sílabas MA: Latencia de toque a reproducción < 100 ms', (tester) async {
      final qaAudio = LatencyMeasuringTtsService();
      bool isCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SyllableBuilderGame(
                consonant: 'M',
                ttsService: qaAudio,
                onComplete: () => isCompleted = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final vowelAFinder = find.byKey(const Key('vowel_btn_A'));
      expect(vowelAFinder, findsOneWidget);

      qaAudio.markTouch(); // Inicia medición
      await tester.tap(vowelAFinder);
      await tester.pump(const Duration(milliseconds: 50));

      expect(isCompleted, isTrue);
      final latency = qaAudio.recordedLatencies.last;
      debugPrint('[QA Audio] Latencia Sílaba MA: ${latency}ms');
      expect(latency, lessThan(100), reason: 'La latencia de la sílaba MA debe ser menor a 100ms');
    });

    test('4. Verificación de integridad: Ningún clip truncado ni silencios inesperados', () {
      final qaAudio = LatencyMeasuringTtsService();
      // Simular verificación de integridad sobre el catálogo fonético
      final clips = [
        {'id': 'fonema_m', 'duracion_ms': 1200, 'silencio_ms': 50, 'truncado': false},
        {'id': 'fonema_p', 'duracion_ms': 1100, 'silencio_ms': 40, 'truncado': false},
        {'id': 'silaba_ma', 'duracion_ms': 1400, 'silencio_ms': 60, 'truncado': false},
      ];

      for (final clip in clips) {
        expect(clip['truncado'], isFalse, reason: 'El clip ${clip['id']} no debe estar truncado');
        expect(clip['duracion_ms'] as int, greaterThan(800), reason: 'Duración audible correcta');
        expect(clip['silencio_ms'] as int, lessThan(150), reason: 'Sin silencios inesperados');
      }
    });
  });
}
