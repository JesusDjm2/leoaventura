import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/services/tts_service.dart';
import 'package:leo_parvulos_app/widgets/letter_tracing.dart';

void main() {
  testWidgets('LetterTracing widget renders guide letter, captures trace, triggers audio and visual celebration', (tester) async {
    // Configurar viewport amplio para pruebas responsivas
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final ttsService = ParvuloTtsService();
    bool completedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LetterTracing(
              letter: 'm',
              ttsService: ttsService,
              onComplete: () {
                completedCalled = true;
              },
            ),
          ),
        ),
      ),
    );

    // Permitir frame inicial para instrucciones de voz post-frame
    await tester.pumpAndSettle();

    // 1. Verificar estado inicial
    expect(find.text('Traza la letra "M"'), findsOneWidget);
    expect(find.byKey(const Key('tracing_canvas_gesture')), findsOneWidget);
    expect(ttsService.audioLogs, contains('¡Hola! Traza la letra M con tu dedito.'));

    // 2. Simular el trazo táctil recorriendo todos los puntos de la 'm'
    final canvasFinder = find.byKey(const Key('tracing_canvas_gesture'));
    final topLeft = tester.getTopLeft(canvasFinder);
    final canvasSize = tester.getSize(canvasFinder);

    final checkpoints = _LetterTracingState.normalizedCheckpointsM;
    expect(checkpoints.isNotEmpty, isTrue);

    final firstPoint = Offset(
      topLeft.dx + canvasSize.width * checkpoints.first.dx,
      topLeft.dy + canvasSize.height * checkpoints.first.dy,
    );

    final gesture = await tester.startGesture(firstPoint);
    await tester.pump(const Duration(milliseconds: 20));

    for (int i = 1; i < checkpoints.length; i++) {
      final cp = checkpoints[i];
      final target = Offset(
        topLeft.dx + canvasSize.width * cp.dx,
        topLeft.dy + canvasSize.height * cp.dy,
      );
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 30));
    }

    await gesture.up();
    // Avanzar la animación de celebración a un estado donde todos los elementos sean visibles
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Verificación determinista del éxito
    expect(completedCalled, isTrue, reason: 'El callback onComplete debe ser invocado');
    expect(find.byKey(const Key('celebration_overlay')), findsOneWidget, reason: 'La animación celebratoria debe estar visible');
    expect(find.text('¡Excelente!'), findsOneWidget);

    // 4. Verificación de audio TTS y fonema
    expect(
      ttsService.audioLogs.any((log) => log.contains('¡Excelente! Has trazado la letra M')),
      isTrue,
      reason: 'El audio TTS con el fonema debe haber sido emitido',
    );

    // 5. Captura determinista de pantalla del estado de éxito con animación
    final boundaryFinder = find.byKey(const Key('tracing_repaint_boundary'));
    final boundary = tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
    // toImage/toByteData usan el engine real: deben ejecutarse fuera de FakeAsync
    // o el test queda colgado indefinidamente.
    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData!.buffer.asUint8List();
    }))!;

    final targetPaths = [
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence/letter_m_success.png',
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/.antigravity/evidence/letter_m_success.png',
      'C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf/letter_m_success.png',
    ];

    for (final path in targetPaths) {
      final file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }

    // Avanzar suficiente tiempo para que la animación de 1400ms termine limpiamente
    await tester.pump(const Duration(milliseconds: 1500));
  });
}

// Extensión para acceder a los checkpoints de prueba
abstract class _LetterTracingState {
  static const List<Offset> normalizedCheckpointsM = [
    Offset(0.22, 0.35),
    Offset(0.22, 0.55),
    Offset(0.22, 0.75),
    Offset(0.36, 0.35),
    Offset(0.50, 0.55),
    Offset(0.50, 0.75),
    Offset(0.64, 0.35),
    Offset(0.78, 0.55),
    Offset(0.78, 0.75),
  ];
}
