import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/main.dart';
import 'package:leo_parvulos_app/reports/parent_report_models.dart';
import 'package:leo_parvulos_app/reports/parent_report_screen.dart';
import 'package:leo_parvulos_app/reports/report_pdf_exporter.dart';

class _FakeExporter implements ReportPdfExporter {
  final exported = <ParentReport>[];
  @override
  Future<void> export(ParentReport report) async => exported.add(report);
}

/// Revisión de UI automatizada: contraste AA + objetivos táctiles + etiquetas.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline)); // 48dp
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline)); // 44pt
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline)); // 4.5:1
}

void main() {
  const viewports = {
    'móvil (412×915)': Size(412, 915),
    'web (1440×900)': Size(1440, 900),
  };

  for (final MapEntry(key: name, value: size) in viewports.entries) {
    testWidgets('ParentReportScreen en $name: gráfico, tiempo, PDF y a11y',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final exporter = _FakeExporter();
      final report = ParentReport.mock();

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: ParentReportScreen(report: report, exporter: exporter),
      ));
      await tester.pumpAndSettle();

      // Sin errores de layout (overflow, constraints) durante el render.
      expect(tester.takeException(), isNull);

      // Gráfico de barras con un grupo por fonema, renderizado con tamaño.
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups, hasLength(report.phonemes.length));
      expect(
        chart.data.barGroups.map((g) => g.barRods.single.toY),
        report.phonemes.map((p) => p.mastery.toDouble()),
      );
      final chartSize = tester.getSize(find.byKey(const Key('phoneme_bar_chart')));
      expect(chartSize.height, 260);
      expect(chartSize.width, greaterThan(300));
      for (final p in report.phonemes) {
        expect(
          find.descendant(
            of: find.byKey(const Key('phoneme_bar_chart')),
            matching: find.text(p.phoneme),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.bySemanticsLabel(RegExp(r'^Gráfico de barras de progreso por fonema')),
        findsOneWidget,
      );

      // Tiempo total de práctica.
      expect(find.text('Tiempo total de práctica'), findsOneWidget);
      expect(find.text('4 h 35 min'), findsOneWidget);

      await expectAccessible(tester);

      // Botón Exportar PDF (fuera de pantalla en móvil → desplazar).
      final button = find.byKey(const Key('export_pdf_button'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await expectAccessible(tester);

      await tester.tap(button);
      await tester.pump();
      expect(exporter.exported, [report]);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Reporte PDF generado'), findsOneWidget);

      semantics.dispose();
    });
  }

  testWidgets('navegación: desde el juego se abre el panel de padres',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LeoParvulosApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('open_parent_report')));
    await tester.pumpAndSettle();

    expect(find.byType(ParentReportScreen), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('buildParentReportPdf genera un PDF válido', () async {
    final bytes = await buildParentReportPdf(ParentReport.mock());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1500));
  });

  test('formatPracticeDuration', () {
    expect(formatPracticeDuration(const Duration(hours: 4, minutes: 35)),
        '4 h 35 min');
    expect(formatPracticeDuration(const Duration(minutes: 45)), '45 min');
    expect(formatPracticeDuration(const Duration(hours: 2)), '2 h');
  });
}
