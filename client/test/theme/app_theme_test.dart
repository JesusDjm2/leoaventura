import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';

void main() {
  setUpAll(() {
    // Igual que en producción: nada de red, todo desde assets/google_fonts/.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Estilo efectivo con el que se pinta un texto (tras heredar del tema).
  TextStyle renderedStyle(WidgetTester tester, String text) => tester
      .widget<RichText>(find.descendant(of: find.text(text), matching: find.byType(RichText)))
      .text
      .style!;

  Widget app(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      );

  group('tipografía', () {
    testWidgets('headlineLarge usa Baloo 2 y azul marino', (tester) async {
      await tester.pumpWidget(app(Builder(
        builder: (context) => Text(
          '¡Hola, Leo!',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      )));

      final style = renderedStyle(tester, '¡Hola, Leo!');
      // google_fonts nombra la familia "<Familia>_<variante>": Baloo2_700.
      expect(style.fontFamily, 'Baloo2_700');
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, AppColors.navy);
      expect(style.color, const Color(0xFF1A3965));
      expect(style.fontSize, 32);

      // La fuente existe empaquetada y se carga sin red.
      await tester.runAsync(() => GoogleFonts.pendingFonts());
    });

    testWidgets('el contenido de lectura (body) usa Andika', (tester) async {
      await tester.pumpWidget(app(const Text('mamá ama a Memo')));
      final style = renderedStyle(tester, 'mamá ama a Memo');
      expect(style.fontFamily, 'Andika_regular');
      expect(style.color, AppColors.navy);
      expect(style.fontSize, 18); // bodyMedium es el estilo por defecto de Text
      await tester.runAsync(() => GoogleFonts.pendingFonts());
    });

    test('display/headline/title en Baloo 2; body/label en Andika', () {
      final t = AppTheme.light().textTheme;
      final display = [t.displayLarge, t.displayMedium, t.displaySmall, t.headlineLarge,
          t.headlineMedium, t.headlineSmall, t.titleLarge, t.titleMedium, t.titleSmall, t.labelLarge];
      final reading = [t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelMedium, t.labelSmall];
      for (final s in display) {
        expect(s!.fontFamily, startsWith('Baloo2_'));
        expect(s.color, AppColors.navy);
      }
      for (final s in reading) {
        expect(s!.fontFamily, startsWith('Andika_'));
        expect(s.color, AppColors.navy);
        expect([FontWeight.w400, FontWeight.w700], contains(s.fontWeight),
            reason: 'Andika solo trae 400 y 700');
      }
    });

    testWidgets('todas las variantes usadas están empaquetadas (sin descargas)', (tester) async {
      final manifest = await tester.runAsync(() => AssetManifest.loadFromAssetBundle(rootBundle));
      final assets = manifest!.listAssets();
      for (final f in [
        'Baloo2-Regular', 'Baloo2-Medium', 'Baloo2-SemiBold', 'Baloo2-Bold', 'Baloo2-ExtraBold',
        'Andika-Regular', 'Andika-Bold', 'Andika-Italic', 'Andika-BoldItalic',
      ]) {
        expect(assets, contains('assets/google_fonts/$f.ttf'));
      }
      expect(assets, containsAll(['assets/google_fonts/OFL-Baloo2.txt', 'assets/google_fonts/OFL-Andika.txt']));

      // Pinta todos los estilos del tema y exige que carguen desde assets.
      final t = AppTheme.light().textTheme;
      await tester.pumpWidget(app(Column(children: [
        for (final s in [t.displayLarge, t.displayMedium, t.displaySmall, t.headlineLarge,
            t.headlineMedium, t.headlineSmall, t.titleLarge, t.titleMedium, t.titleSmall,
            t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall])
          Text('Aa', style: s),
        Text('Aa', style: AppTypography.readingWord()),
      ])));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
    });
  });

  group('colores', () {
    test('AppColors expone los colores extraídos del logo', () {
      expect(AppColors.sky, const Color(0xFFADE0FC)); // azul fondo
      expect(AppColors.brandOrange, const Color(0xFFFE8E15)); // naranja primario (marca)
      expect(AppColors.brandGreen, const Color(0xFF93D741)); // verde secundario (marca)
      expect(AppColors.navy, const Color(0xFF1A3965)); // azul marino texto
      expect(AppColors.brandCyan, const Color(0xFF32BCE4));
      expect(AppColors.background, AppColors.sky);
    });

    test('ColorScheme semántico (primary, secondary, error, surface)', () {
      final s = AppTheme.light().colorScheme;
      expect(s.primary, AppColors.primary);
      expect(s.secondary, AppColors.secondary);
      expect(s.error, AppColors.error);
      expect(s.surface, AppColors.surface);
      expect(s.onSurface, AppColors.navy);
      expect(s.primaryContainer, AppColors.brandOrange);
      expect(s.secondaryContainer, AppColors.brandGreen);
      expect(AppTheme.light().scaffoldBackgroundColor, AppColors.background);
    });

    test('AppColors.primary contra el fondo de la app cumple WCAG AA (≥ 4.5:1)', () {
      final ratio = AppContrast.ratio(AppColors.primary, AppColors.background);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'ratio ${ratio.toStringAsFixed(2)}:1');
      expect(AppContrast.meetsAA(AppColors.primary, AppColors.background), isTrue);
    });

    test('el naranja de marca NO cumple AA sobre el fondo (por eso existe primary)', () {
      expect(AppContrast.ratio(AppColors.brandOrange, AppColors.background), lessThan(3));
    });

    test('todas las parejas texto/fondo del ColorScheme cumplen AA', () {
      final s = AppTheme.light().colorScheme;
      final bg = AppColors.background;
      final pairs = <String, (Color, Color)>{
        'primary/background': (s.primary, bg),
        'secondary/background': (s.secondary, bg),
        'tertiary/background': (s.tertiary, bg),
        'error/background': (s.error, bg),
        'onSurface/background': (s.onSurface, bg),
        'onSurfaceVariant/background': (s.onSurfaceVariant, bg),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onTertiary/tertiary': (s.onTertiary, s.tertiary),
        'onError/error': (s.onError, s.error),
        'onPrimaryContainer/primaryContainer': (s.onPrimaryContainer, s.primaryContainer),
        'onSecondaryContainer/secondaryContainer': (s.onSecondaryContainer, s.secondaryContainer),
        'onTertiaryContainer/tertiaryContainer': (s.onTertiaryContainer, s.tertiaryContainer),
        'onErrorContainer/errorContainer': (s.onErrorContainer, s.errorContainer),
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'primary/surface': (s.primary, s.surface),
        'onSurface/surfaceContainerHighest': (s.onSurface, s.surfaceContainerHighest),
        'onInverseSurface/inverseSurface': (s.onInverseSurface, s.inverseSurface),
      };
      final failures = [
        for (final MapEntry(key: name, value: (fg, bgc)) in pairs.entries)
          if (!AppContrast.meetsAA(fg, bgc)) '$name ${AppContrast.ratio(fg, bgc).toStringAsFixed(2)}:1',
      ];
      expect(failures, isEmpty);
      // Bordes de componentes: ≥ 3:1 (WCAG 1.4.11).
      expect(AppContrast.meetsAALarge(s.outline, s.surface), isTrue);
      expect(AppContrast.meetsAALarge(s.outline, bg), isTrue);
    });

    test('AppContrast coincide con valores de referencia WCAG', () {
      expect(AppContrast.ratio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(AppContrast.ratio(const Color(0xFF777777), Colors.white), closeTo(4.48, 0.01));
    });
  });

  testWidgets('botón principal: naranja de marca, texto azul marino, ≥ 48 dp y AA', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(FilledButton(onPressed: () {}, child: const Text('¡Jugar!'))));
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
    expect(renderedStyle(tester, '¡Jugar!').color, AppColors.navy);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
