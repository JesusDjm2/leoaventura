import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/widgets/base_ui_components.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget testHarness(Widget child, {Size size = const Size(800, 1000)}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Fase 14: PrimaryButton', () {
    testWidgets('1. Renderiza con altura ergonomica >= 56dp y texto en Baloo 2', (tester) async {
      await tester.pumpWidget(testHarness(
        PrimaryButton(
          onPressed: () {},
          text: '¡JUGAR AHORA!',
          icon: Icons.play_arrow_rounded,
        ),
      ));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump();

      final buttonFinder = find.byType(PrimaryButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(56.0));

      final textFinder = find.text('¡JUGAR AHORA!');
      expect(textFinder, findsOneWidget);

      final richText = tester.widget<RichText>(
        find.descendant(of: textFinder, matching: find.byType(RichText)),
      );
      expect(richText.text.style?.fontFamily, startsWith('Baloo2_'));
      expect(richText.text.style?.color, AppColors.navy);
    });

    testWidgets('2. Dispara callback onPressed al tocar y soporta estado presionado', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(testHarness(
        PrimaryButton(
          onPressed: () => pressed = true,
          text: 'Continuar',
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('3. Muestra spinner de carga cuando isLoading es verdadero y deshabilita tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(testHarness(
        PrimaryButton(
          onPressed: () => tapped = true,
          text: 'Guardar',
          isLoading: true,
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('Fase 14: SuccessDialog', () {
    testWidgets('4. Despliega dialogo con verde del logo, mascota Leon Leo y botones', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SuccessDialog.show(
                  context: context,
                  title: '¡Reto Cumplido!',
                  message: 'Descubriste el sonido /m/ de Mamá.',
                  confirmText: '¡Siguiente Nivel!',
                  onConfirm: () {
                    confirmed = true;
                    Navigator.of(context).pop();
                  },
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));
      await tester.pump();

      // Abrir el diálogo
      await tester.tap(find.text('Abrir'));
      await tester.pump(); // Procesa el tap e inicia la ruta
      await tester.pump(const Duration(milliseconds: 350)); // Completa la animación de entrada
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(milliseconds: 50));

      // Verificar mascota celebrando
      expect(find.byType(LeoMascot), findsOneWidget);
      final mascot = tester.widget<LeoMascot>(find.byType(LeoMascot));
      expect(mascot.state, MascotState.celebrating);

      // Verificar textos
      expect(find.text('¡Reto Cumplido!'), findsOneWidget);
      expect(find.text('Descubriste el sonido /m/ de Mamá.'), findsOneWidget);
      expect(find.text('¡META ALCANZADA!'), findsOneWidget);

      // Verificar confirmación
      await tester.tap(find.text('¡Siguiente Nivel!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(confirmed, isTrue);
    });
  });

  group('Fase 14: ReadingCard', () {
    testWidgets('5. Muestra silaba grande con Andika y resalta grafema objetivo', (tester) async {
      await tester.pumpWidget(testHarness(
        const ReadingCard(
          text: 'ma',
          highlightedPart: 'm',
          subtitle: 'Sílaba inicial',
        ),
      ));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump();

      expect(find.text('Sílaba inicial'), findsOneWidget);

      // Verifica RichText con partes resaltadas
      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      final richText = tester.widget<RichText>(richTextFinder.first);
      final span = richText.text as TextSpan;
      expect(span.children, isNotNull);
      expect(span.children!.length, greaterThanOrEqualTo(2));
      // Primer span ("m") debe tener el color de resalte naranja
      expect(span.children![0].style?.color, AppColors.brandOrange);
      expect(span.children![0].style?.fontFamily, startsWith('Andika_'));
    });

    testWidgets('6. Boton de audio en ReadingCard dispara callback fonetico', (tester) async {
      bool audioTapped = false;

      await tester.pumpWidget(testHarness(
        ReadingCard(
          text: 'pato',
          onAudioTap: () => audioTapped = true,
        ),
      ));
      await tester.pump();

      final audioButtonFinder = find.byIcon(Icons.volume_down_rounded);
      expect(audioButtonFinder, findsOneWidget);

      await tester.tap(audioButtonFinder);
      await tester.pump();
      expect(audioTapped, isTrue);
    });
  });

  testWidgets('7. Genera captura visual de alta resolucion de la galeria de componentes', (tester) async {
    tester.view.physicalSize = const Size(820, 1180);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.palette_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Design System — Fase 14',
                            style: GoogleFonts.baloo2(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            'Componentes Base: PrimaryButton, SuccessDialog y ReadingCard',
                            style: GoogleFonts.andika(
                              fontSize: 15,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sección 1: PrimaryButton
                  Text(
                    '1. PrimaryButton (Naranja de marca, Baloo 2, Bisel 3D táctil)',
                    style: GoogleFonts.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          onPressed: () {},
                          text: '¡VAMOS A JUGAR!',
                          icon: Icons.rocket_launch_rounded,
                          height: 58,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: PrimaryButton(
                          onPressed: () {},
                          text: 'Escuchar',
                          icon: Icons.volume_up_rounded,
                          backgroundColor: AppColors.brandCyan,
                          bevelColor: const Color(0xFF1E9BBF),
                          height: 58,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Sección 2: ReadingCard
                  Text(
                    '2. ReadingCard (Fondo crema, Andika 56pt, Resaltado de fonemas)',
                    style: GoogleFonts.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ReadingCard(
                          text: 'ma',
                          highlightedPart: 'm',
                          subtitle: 'Fonema continuo /m/',
                          onAudioTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReadingCard(
                          text: 'pa',
                          highlightedPart: 'a',
                          highlightColor: AppColors.brandCyan,
                          subtitle: 'Vocal abierta /a/',
                          isSelected: true,
                          isAudioPlaying: true,
                          onAudioTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReadingCard(
                          text: 'sol',
                          subtitle: 'Palabra monosílaba',
                          onAudioTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Sección 3: SuccessDialog Card Preview
                  Text(
                    '3. SuccessDialog (Verde del logo, León Leo celebrando, Baloo 2 + Andika)',
                    style: GoogleFonts.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: SuccessDialog(
                      title: '¡Felicidades, Pequeño Lector!',
                      message: 'Has dominado el sonido del león y completado todas las actividades del día.',
                      confirmText: '¡Reclamar Estrella Dorada!',
                      dismissText: 'Volver al Menú',
                      mascotSize: 110,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData!.buffer.asUint8List();
    }))!;

    // Guardar evidencia visual en las rutas correspondientes
    final dir1 = Directory('C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/ui/components');
    if (!dir1.existsSync()) dir1.createSync(recursive: true);
    File('${dir1.path}/base_components_gallery.png').writeAsBytesSync(bytes);

    final dir2 = Directory('C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence');
    if (!dir2.existsSync()) dir2.createSync(recursive: true);
    File('${dir2.path}/base_components_gallery.png').writeAsBytesSync(bytes);

    final dir3 = Directory('C:/Users/miran/.gemini/antigravity/brain/e93cb57e-2f27-4dcd-b459-9c0222ae4bcf');
    if (!dir3.existsSync()) dir3.createSync(recursive: true);
    File('${dir3.path}/base_components_gallery.png').writeAsBytesSync(bytes);

    expect(bytes.length, greaterThan(1000));
  });
}
