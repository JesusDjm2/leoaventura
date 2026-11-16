import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leo_parvulos_app/screens/ui_playground_screen.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';
import 'package:leo_parvulos_app/ui/primary_button.dart';
import 'package:leo_parvulos_app/ui/reading_card.dart';
import 'package:leo_parvulos_app/ui/success_dialog.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester, Widget home, {Size size = const Size(1280, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: home));
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();
  }

  group('solo tokens de app_theme.dart', () {
    test('los componentes no definen colores, fuentes ni estilos propios', () {
      final files = [
        ...Directory('lib/ui').listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
        File('lib/screens/ui_playground_screen.dart'),
      ];
      expect(files.length, greaterThanOrEqualTo(4));
      final forbidden = {
        'color literal': RegExp(r'Color\(0x'),
        'Colors.*': RegExp(r'\bColors\.'),
        'fontFamily': RegExp(r'fontFamily'),
        'GoogleFonts directo': RegExp(r'GoogleFonts\.'),
        'TextStyle nuevo': RegExp(r'\bTextStyle\('),
        'Color.fromARGB/RGBO': RegExp(r'Color\.from'),
      };
      final violations = <String>[];
      for (final f in files) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          forbidden.forEach((what, re) {
            if (re.hasMatch(line)) violations.add('${f.path}:${i + 1} $what → ${line.trim()}');
          });
        }
      }
      expect(violations, isEmpty);
    });
  });

  group('UI Playground', () {
    const viewports = {
      'tablet horizontal 1280×800': Size(1280, 800),
      'tablet vertical 800×1280': Size(800, 1280),
      'teléfono 412×915': Size(412, 915),
    };
    for (final MapEntry(key: name, value: size) in viewports.entries) {
      testWidgets('$name: los 3 componentes, sin overflow y accesible', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(tester, const UiPlaygroundScreen(), size: size);

        expect(tester.takeException(), isNull, reason: 'overflow o error de layout');
        expect(find.byType(ReadingCard), findsNWidgets(3));
        expect(find.byType(PrimaryButton), findsNWidgets(5)); // 4 + el del diálogo
        expect(find.byType(SuccessDialog), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        // Auditoría de la página entera sin recortes de scroll: misma anchura,
        // altura suficiente para que todo quepa (un nodo cortado por el borde
        // del scroll daría un falso "objetivo táctil < 48 dp").
        tester.view.physicalSize = Size(size.width, 2400);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('open_success_dialog')).hitTestable(), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }

    testWidgets('en tablet la palabra se pinta a 72 dp, sin reducirse', (tester) async {
      await pumpApp(tester, const UiPlaygroundScreen());
      final words = find.byKey(const Key('reading_card_word'));
      expect(words, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        final finder = words.at(i);
        final rich = tester.widget<RichText>(find.descendant(of: finder, matching: find.byType(RichText)));
        final spans = <TextStyle>[];
        rich.text.visitChildren((s) {
          if (s is TextSpan && s.text != null) spans.add(s.style ?? rich.text.style!);
          return true;
        });
        if (spans.isEmpty) spans.add(rich.text.style!);
        for (final st in spans) {
          expect(st.fontSize, 72);
          expect(st.fontFamily, 'Andika_700');
          expect([AppColors.navy, AppColors.primary], contains(st.color));
        }
        // FittedBox no escaló: tamaño pintado == tamaño natural.
        final natural = tester.getSize(finder);
        final painted = tester.getRect(finder);
        expect(painted.width, closeTo(natural.width, 0.5));
        expect(painted.height, greaterThanOrEqualTo(72));
      }
    });
  });

  group('ReadingCard', () {
    testWidgets('sílabas alternan azul marino / naranja AA', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: SizedBox(width: 320, child: ReadingCard(word: 'mamá', syllables: ['ma', 'má']))));
      final rich = tester.widget<RichText>(find.descendant(
          of: find.byKey(const Key('reading_card_word')), matching: find.byType(RichText)));
      final colors = <Color?>[];
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text != null) colors.add(s.style?.color);
        return true;
      });
      expect(colors, [AppColors.navy, AppColors.primary]);
      expect(tester.getSemantics(find.byType(ReadingCard)).label, 'mamá, sílabas: ma - má');
      // Ambos colores de sílaba cumplen AA sobre la tarjeta blanca.
      expect(AppContrast.meetsAA(AppColors.navy, AppColors.surface), isTrue);
      expect(AppContrast.meetsAA(AppColors.primary, AppColors.surface), isTrue);
      semantics.dispose();
    });

    testWidgets('una palabra larga en una tarjeta angosta se reduce, sin overflow', (tester) async {
      await pumpApp(tester, const Center(child: SizedBox(width: 180, child: ReadingCard(word: 'hipopótamo'))));
      expect(tester.takeException(), isNull);
      final f = find.byKey(const Key('reading_card_word'));
      expect(tester.getRect(f).width, lessThanOrEqualTo(180));
    });
  });

  group('PrimaryButton', () {
    testWidgets('pulsar llama a onPressed; loading y deshabilitado bloquean', (tester) async {
      var taps = 0;
      Widget build({bool loading = false, bool enabled = true}) => Center(
            child: PrimaryButton(
              label: '¡Empezar!',
              isLoading: loading,
              onPressed: enabled ? () => taps++ : null,
            ),
          );

      await pumpApp(tester, build());
      expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(48));
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);

      await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: build(loading: true)));
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: build(enabled: false)));
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
    });

    testWidgets('etiqueta en Baloo 2 azul marino sobre naranja de marca', (tester) async {
      await pumpApp(tester, Center(child: PrimaryButton(label: 'Seguir', onPressed: () {})));
      final style = tester.widget<RichText>(find.descendant(
          of: find.text('Seguir'), matching: find.byType(RichText))).text.style!;
      expect(style.fontFamily, 'Baloo2_700');
      expect(style.color, AppColors.navy);
      final faces = tester.widgetList<AnimatedContainer>(find.descendant(
          of: find.byType(PrimaryButton), matching: find.byType(AnimatedContainer)));
      expect((faces.single.decoration! as BoxDecoration).color, AppColors.brandOrange);
    });
  });

  group('SuccessDialog', () {
    testWidgets('show() abre el modal y "¡Seguir!" lo cierra', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        Builder(
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => SuccessDialog.show(ctx, title: '¡Lo lograste!', stars: 3),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('¡Lo lograste!'), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const Key('success_star_0'))).label, '3 de 3 estrellas');
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('success_continue')));
      await tester.pumpAndSettle();
      expect(find.byType(SuccessDialog), findsNothing);
      semantics.dispose();
    });
  });
}
