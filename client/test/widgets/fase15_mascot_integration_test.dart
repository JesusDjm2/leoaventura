import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/screens/home_screen.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/base_ui_components.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Fase 15: Integración de la Mascota Leo en Home y SuccessDialog', () {
    testWidgets('1. HomeScreen muestra al león Leo como guía accesible sin bloquear botones', (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintBoundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: RepaintBoundary(
            key: repaintBoundaryKey,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(milliseconds: 200));

      // 1.1 Verificar presencia de la mascota Leo en Home
      final leoFinder = find.byKey(const Key('home_leo_mascot'));
      expect(leoFinder, findsOneWidget);
      final leoSize = tester.getSize(leoFinder);
      expect(leoSize.width, greaterThanOrEqualTo(48.0));
      expect(leoSize.height, greaterThanOrEqualTo(48.0));

      // 1.2 Verificar que todos los botones de interacción están libres y accesibles
      final cardMFinder = find.byKey(const Key('activity_card_m'));
      expect(cardMFinder, findsOneWidget);
      final cardPFinder = find.byKey(const Key('activity_card_p'));
      expect(cardPFinder, findsOneWidget);
      final settingsFinder = find.byKey(const Key('home_settings_btn'));
      expect(settingsFinder, findsOneWidget);
      final reportsFinder = find.byKey(const Key('home_reports_btn'));
      expect(reportsFinder, findsOneWidget);

      // Verificar que ningún botón colisiona con el león
      final leoRect = tester.getRect(leoFinder);
      final cardMRect = tester.getRect(cardMFinder);
      final cardPRect = tester.getRect(cardPFinder);

      expect(leoRect.overlaps(cardMRect), isFalse, reason: 'El león no debe solapar la tarjeta M');
      expect(leoRect.overlaps(cardPRect), isFalse, reason: 'El león no debe solapar la tarjeta P');

      // 1.3 Capturar pantalla de Home con Leo correctamente escalado
      final boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return byteData!.buffer.asUint8List();
      }))!;

      for (final dirPath in [
        'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/ui/mascot',
        'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence',
        'C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf',
      ]) {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) dir.createSync(recursive: true);
        File('${dir.path}/home_screen_with_leo.png').writeAsBytesSync(bytes);
      }
    });

    testWidgets('2. SuccessDialog muestra al león celebrando sin bloquear acciones', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintBoundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: RepaintBoundary(
              key: repaintBoundaryKey,
              child: const Center(
                child: SuccessDialog(
                  title: '¡Misión Cumplida, Campeón!',
                  message: 'Completaste el trazado de la letra M y escuchaste su fonema.',
                  confirmText: '¡Continuar!',
                  dismissText: 'Volver al Inicio',
                  showMascot: true,
                  mascotSize: 120,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(milliseconds: 200));

      // 2.1 Verificar presencia de Leo en modo celebración
      final mascotFinder = find.byType(LeoMascot);
      expect(mascotFinder, findsOneWidget);
      final mascotWidget = tester.widget<LeoMascot>(mascotFinder);
      expect(mascotWidget.state, MascotState.celebrating);

      // 2.2 Verificar botones interactivos libres
      final confirmBtn = find.text('¡Continuar!');
      expect(confirmBtn, findsOneWidget);
      final dismissBtn = find.text('Volver al Inicio');
      expect(dismissBtn, findsOneWidget);

      final confirmRect = tester.getRect(confirmBtn);
      final mascotRect = tester.getRect(mascotFinder);
      expect(mascotRect.overlaps(confirmRect), isFalse, reason: 'El león no debe bloquear el botón de confirmación');

      // 2.3 Capturar pantalla del diálogo de éxito con Leo celebrando
      final boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return byteData!.buffer.asUint8List();
      }))!;

      for (final dirPath in [
        'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/ui/mascot',
        'C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence',
        'C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf',
      ]) {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) dir.createSync(recursive: true);
        File('${dir.path}/success_dialog_with_leo.png').writeAsBytesSync(bytes);
      }
    });
  });
}
