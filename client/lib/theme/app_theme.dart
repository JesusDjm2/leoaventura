/// Design system de LeoAventura: colores, tipografía y ThemeData central.
///
/// Paleta extraída del logo (`docs/design/brand/leoaventura_logo.png`).
/// Ver `docs/design/design_system.md`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

/// Colores del design system.
///
/// Hay dos capas:
/// * **Marca** (`brand*`, [sky], [navy]): los colores exactos del logo. Los
///   tonos vivos (naranja, verde, celeste) no alcanzan contraste AA sobre el
///   fondo celeste ni con texto blanco; se usan como relleno de superficies
///   grandes (botones, tarjetas de actividad, ilustraciones) con texto
///   [navy] encima, combinación que sí cumple AA (5.0–6.6:1).
/// * **Semánticos** ([primary], [secondary], [tertiary], [error]...): mismos
///   tonos oscurecidos hasta cumplir WCAG AA (≥ 4.5:1) sobre [background] y
///   con texto blanco encima. Son los que se usan para texto, iconos y bordes.
abstract final class AppColors {
  // ---------------------------------------------------------------- Marca
  /// Azul del fondo del logo. Fondo de la app.
  static const Color sky = Color(0xFFADE0FC);

  /// Naranja de "LEO" en el logo.
  static const Color brandOrange = Color(0xFFFE8E15);

  /// Verde de "AVENT" en el logo.
  static const Color brandGreen = Color(0xFF93D741);

  /// Celeste de "URA" en el logo.
  static const Color brandCyan = Color(0xFF32BCE4);

  /// Azul marino del contorno del logotipo. Color de texto.
  static const Color navy = Color(0xFF1A3965);

  // ----------------------------------------------------------- Semánticos
  /// Naranja accesible (4.56:1 sobre [background], 6.45:1 con texto blanco).
  static const Color primary = Color(0xFF924C01);

  /// Verde accesible (4.53:1 sobre [background], 6.41:1 con texto blanco).
  static const Color secondary = Color(0xFF446916);

  /// Celeste accesible (4.53:1 sobre [background], 6.41:1 con texto blanco).
  static const Color tertiary = Color(0xFF116780);

  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  /// Fondo de la app (scaffold).
  static const Color background = sky;

  /// Superficies de contenido (tarjetas, hojas de lectura).
  static const Color surface = Color(0xFFFFFFFF);

  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Texto principal.
  static const Color text = navy;

  /// Texto secundario (≥ 4.5:1 sobre [surface] y [background]).
  static const Color textMuted = Color(0xFF3E5A7E);

  /// Bordes de componentes (≥ 3:1 sobre [surface] y [background], WCAG 1.4.11).
  static const Color outline = Color(0xFF4A7DB7);
  static const Color outlineVariant = Color(0xFFB9D3EA);

  // Contenedores de superficie: tintes del celeste de marca.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3FAFF);
  static const Color surfaceContainer = Color(0xFFE6F5FE);
  static const Color surfaceContainerHigh = Color(0xFFD6EEFD);
  static const Color surfaceContainerHighest = Color(0xFFC6E8FC);
}

/// Utilidades de contraste WCAG 2.x (usa la luminancia relativa de Flutter).
abstract final class AppContrast {
  /// Ratio de contraste entre dos colores opacos (1.0 – 21.0).
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// AA para texto normal (≥ 4.5:1).
  static bool meetsAA(Color fg, Color bg) => ratio(fg, bg) >= 4.5;

  /// AA para texto grande (≥ 18 pt, o 14 pt en negrita) y componentes de UI (≥ 3:1).
  static bool meetsAALarge(Color fg, Color bg) => ratio(fg, bg) >= 3.0;
}

/// Tipografía: **Baloo 2** para títulos (display/headline/title y botones),
/// **Andika** para el contenido de lectura (body/label). Andika está diseñada
/// para lectores principiantes: "a" y "g" de un solo piso, y letras que no
/// se confunden (I/l/1, b/d/p/q).
///
/// Las fuentes van empaquetadas en `assets/google_fonts/` (la app es
/// offline-first); `google_fonts` las toma de ahí sin red.
abstract final class AppTypography {
  static const String displayFamily = 'Baloo 2';
  static const String readingFamily = 'Andika';

  static TextStyle _baloo(double size, FontWeight weight, {double height = 1.2}) =>
      GoogleFonts.baloo2(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: AppColors.text,
      );

  static TextStyle _andika(double size, {FontWeight weight = FontWeight.w400, double height = 1.5}) =>
      GoogleFonts.andika(
        fontSize: size,
        fontWeight: weight, // Andika solo trae 400 y 700
        height: height,
        color: AppColors.text,
      );

  /// Escala tipográfica (tamaños aumentados respecto a Material 3 para
  /// párvulos: el cuerpo base es 18 en vez de 14).
  static TextTheme textTheme() => TextTheme(
        displayLarge: _baloo(57, FontWeight.w800, height: 1.1),
        displayMedium: _baloo(45, FontWeight.w800, height: 1.1),
        displaySmall: _baloo(36, FontWeight.w700, height: 1.15),
        headlineLarge: _baloo(32, FontWeight.w700),
        headlineMedium: _baloo(28, FontWeight.w700),
        headlineSmall: _baloo(24, FontWeight.w700),
        titleLarge: _baloo(22, FontWeight.w700),
        titleMedium: _baloo(18, FontWeight.w600),
        titleSmall: _baloo(16, FontWeight.w600),
        bodyLarge: _andika(20),
        bodyMedium: _andika(18),
        bodySmall: _andika(16),
        labelLarge: _baloo(18, FontWeight.w700, height: 1.1),
        labelMedium: _andika(16, weight: FontWeight.w700, height: 1.3),
        labelSmall: _andika(14, weight: FontWeight.w700, height: 1.3),
      );

  /// Palabra o letra que el niño debe leer (fuera de la escala M3).
  static TextStyle readingWord({double size = 40}) =>
      _andika(size, weight: FontWeight.w700, height: 1.25).copyWith(letterSpacing: 1.5);
}

/// ThemeData central de la app.
abstract final class AppTheme {
  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.brandOrange,
    onPrimaryContainer: AppColors.navy,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.brandGreen,
    onSecondaryContainer: AppColors.navy,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onPrimary,
    tertiaryContainer: AppColors.brandCyan,
    onTertiaryContainer: AppColors.navy,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.navy,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.brandOrange,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent, // sin tinte naranja en superficies elevadas
  );

  static ThemeData light() {
    final text = AppTypography.textTheme();
    const radius = BorderRadius.all(Radius.circular(20));
    const minTouch = Size(48, 56); // ≥ 48 dp

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.navy, size: 28),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      // Botón principal: naranja de marca con texto azul marino (5.0:1).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.navy,
          minimumSize: minTouch,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.navy,
          minimumSize: minTouch,
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: minTouch,
          side: const BorderSide(color: AppColors.navy, width: 2),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: text.labelMedium,
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      dividerTheme: const DividerThemeData(color: AppColors.outlineVariant),
    );
  }

  /// Registra las licencias OFL de las fuentes empaquetadas y desactiva la
  /// descarga en tiempo de ejecución (todo sale de `assets/google_fonts/`).
  static void configureFonts() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LicenseRegistry.addLicense(() async* {
      for (final (family, file) in [('Baloo 2', 'OFL-Baloo2.txt'), ('Andika', 'OFL-Andika.txt')]) {
        final license = await rootBundle.loadString('assets/google_fonts/$file');
        yield LicenseEntryWithLineBreaks([family], license);
      }
    });
  }
}
