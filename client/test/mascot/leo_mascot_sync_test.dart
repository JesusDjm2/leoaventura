import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/widgets/leo_mascot.dart';

void main() {
  testWidgets('LeoMascot: sincronización con audio (hablando) y captura visual', (tester) async {
    tester.view.physicalSize = const Size(500, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          body: Center(
            child: RepaintBoundary(
              key: const Key('mascot_repaint_talking'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LeoMascot(
                      size: 220,
                      state: MascotState.talking,
                      isAudioPlaying: true,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '¡Hola! Traza la letra M.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Avanzar frame para animación de habla sincronizada
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const Key('mascot_canvas_talking')), findsOneWidget);

    // Captura determinista de pantalla del estado "hablando"
    final boundaryFinder = find.byKey(const Key('mascot_repaint_talking'));
    final boundary = tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData!.buffer.asUint8List();
    }))!;

    final paths = [
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/ui/mascot/mascot_talking.png',
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence/mascot_talking.png',
      'C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf/mascot_talking.png',
    ];

    for (final p in paths) {
      final file = File(p);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }
  });

  testWidgets('LeoMascot: estado celebrando con estrellas y captura visual', (tester) async {
    tester.view.physicalSize = const Size(500, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          body: Center(
            child: RepaintBoundary(
              key: const Key('mascot_repaint_celebrating'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LeoMascot(
                      size: 220,
                      state: MascotState.celebrating,
                      isAudioPlaying: false,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '¡Excelente trabajo!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Avanzar frame para pico de salto y estrellas
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('mascot_canvas_celebrating')), findsOneWidget);

    // Captura determinista de pantalla del estado "celebrando"
    final boundaryFinder = find.byKey(const Key('mascot_repaint_celebrating'));
    final boundary = tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData!.buffer.asUint8List();
    }))!;

    final paths = [
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/ui/mascot/mascot_celebrating.png',
      'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence/mascot_celebrating.png',
      'C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf/mascot_celebrating.png',
    ];

    for (final p in paths) {
      final file = File(p);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }
  });
}
