import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/main.dart';
import 'package:leo_parvulos_app/screens/home_screen.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/bouncy_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Juice & Micro-Interacciones de Leoaventura', () {
    testWidgets('1. BouncyButton usa AnimatedScale, se encoge 5% (0.95) al pulsar y rebota al soltar sin retraso', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: BouncyButton(
                key: const Key('test_bouncy'),
                onTap: () => tapCount++,
                child: Container(
                  width: 220,
                  height: 60,
                  alignment: Alignment.center,
                  color: AppColors.brandOrange,
                  child: const Text('¡Rebota!'),
                ),
              ),
            ),
          ),
        ),
      );

      final bouncyFinder = find.byKey(const Key('test_bouncy'));
      final animatedScaleFinder = find.descendant(
        of: bouncyFinder,
        matching: find.byType(AnimatedScale),
      );

      expect(tester.widget<AnimatedScale>(animatedScaleFinder).scale, 1.0);

      // Al presionar: encoge exactamente un 5% (scale == 0.95)
      final gesture = await tester.startGesture(tester.getCenter(bouncyFinder));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.state<BouncyButtonState>(bouncyFinder).isPressed, isTrue);
      expect(tester.widget<AnimatedScale>(animatedScaleFinder).scale, 0.95);

      // Al soltar: rebota a 1.0 y dispara onTap de inmediato (0ms delay)
      await gesture.up();
      await tester.pump();

      expect(tapCount, 1);
      expect(tester.state<BouncyButtonState>(bouncyFinder).isPressed, isFalse);
      expect(tester.widget<AnimatedScale>(animatedScaleFinder).scale, 1.0);

      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. HomeScreen usa SlideTransition al entrar y NO bloquea toques durante la animación', (tester) async {
      bool navigatedToMinigame = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
          routes: {
            '/minigame': (_) {
              navigatedToMinigame = true;
              return const Scaffold(body: Center(child: Text('Minijuego Activo')));
            },
          },
        ),
      );

      // A los 60ms las SlideTransition están activamente deslizando desde abajo
      await tester.pump(const Duration(milliseconds: 60));
      final slideTransitions = find.byType(SlideTransition);
      expect(slideTransitions, findsAtLeastNWidgets(4));

      // ui_review: tocar la tarjeta de minijuego EN MEDIO de la animación responde al instante
      await tester.tap(find.byKey(const Key('activity_card_m')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(navigatedToMinigame, isTrue);
      expect(find.text('Minijuego Activo'), findsOneWidget);
    });

    testWidgets('3. Tarjetas de minijuegos aplican efecto físico de presión (0.95) y rebote', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
          routes: {
            '/minigame': (_) => const Scaffold(body: SizedBox.shrink()),
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 550));

      final cardM = find.byKey(const Key('activity_card_m'));
      final bouncyInsideCard = find.descendant(
        of: cardM,
        matching: find.byType(BouncyButton),
      );
      final scaleInsideCard = find.descendant(
        of: bouncyInsideCard,
        matching: find.byType(AnimatedScale),
      );

      expect(tester.widget<AnimatedScale>(scaleInsideCard).scale, 1.0);

      final gesture = await tester.startGesture(tester.getCenter(cardM));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widget<AnimatedScale>(scaleInsideCard).scale, 0.95);

      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.widget<AnimatedScale>(scaleInsideCard).scale, 1.0);
    });

    testWidgets('4. Captura secuencia real de frames Flutter para el video demo de Juice', (tester) async {
      tester.view.physicalSize = const Size(460, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final boundaryKey = GlobalKey();
      final framesDir = Directory(
        'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/temp_juice_frames',
      );
      if (framesDir.existsSync()) {
        framesDir.deleteSync(recursive: true);
      }
      framesDir.createSync(recursive: true);
      addTearDown(() {
        if (framesDir.existsSync()) {
          framesDir.deleteSync(recursive: true);
        }
      });

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const LeoParvulosApp(),
        ),
      );
      await tester.runAsync(() => GoogleFonts.pendingFonts());

      int frameIndex = 0;
      Future<void> snapFrame() async {
        final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final bytes = (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return byteData!.buffer.asUint8List();
        }))!;
        final padded = frameIndex.toString().padLeft(4, '0');
        File('${framesDir.path}/frame_$padded.png').writeAsBytesSync(bytes);
        frameIndex++;
      }

      // A. Entrada escalonada con SlideTransition (18 frames ~ 600ms a 30fps)
      for (int i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }

      // Pausa breve en Home completo (8 frames)
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }

      // B. Presión física 5% y rebote en PrimaryButton (Cuenta Familiar)
      final registerBtn = find.byKey(const Key('home_register_flow_btn'));
      final g1 = await tester.startGesture(tester.getCenter(registerBtn));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }
      await g1.cancel();
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }

      // C. Presión física 5% y rebote en Tarjeta de Minijuego Letra P
      final cardP = find.byKey(const Key('activity_card_p'));
      final g2 = await tester.startGesture(tester.getCenter(cardP));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }
      await g2.cancel();
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }

      // D. Presión y navegación real en Tarjeta de Minijuego Letra M -> TracingGameScreen
      final cardM = find.byKey(const Key('activity_card_m'));
      final g3 = await tester.startGesture(tester.getCenter(cardM));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }
      await g3.up();
      for (int i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 33));
        await snapFrame();
      }

      expect(frameIndex, greaterThanOrEqualTo(70));
      expect(tester.takeException(), isNull);
    });
  });
}
