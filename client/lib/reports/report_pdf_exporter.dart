import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'parent_report_models.dart';

/// Exporta un [ParentReport] a PDF. Inyectable para tests.
abstract class ReportPdfExporter {
  Future<void> export(ParentReport report);
}

/// Genera el PDF y abre el diálogo nativo de compartir/descargar
/// (descarga en web, hoja de compartir en Android/iOS).
class PrintingReportPdfExporter implements ReportPdfExporter {
  const PrintingReportPdfExporter();

  @override
  Future<void> export(ParentReport report) async {
    final bytes = await buildParentReportPdf(report);
    final safeName = report.childName.toLowerCase().replaceAll(' ', '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_lectura_$safeName.pdf',
    );
  }
}

const _brand = PdfColor.fromInt(0xFFBF360C);

PdfColor _levelColor(MasteryLevel l) => switch (l) {
      MasteryLevel.mastered => const PdfColor.fromInt(0xFF2E7D32),
      MasteryLevel.inProgress => const PdfColor.fromInt(0xFFB26A00),
      MasteryLevel.initial => const PdfColor.fromInt(0xFFC62828),
    };

Future<Uint8List> buildParentReportPdf(ParentReport r) async {
  final doc = pw.Document(
    title: 'Reporte de lectura - ${r.childName}',
    author: 'LeoPárvulos',
  );
  final d = r.generatedAt;
  String two(int n) => n.toString().padLeft(2, '0');
  final generated =
      '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (ctx) => [
      pw.Text('LeoPárvulos · Reporte de lectura',
          style: pw.TextStyle(
              fontSize: 20, fontWeight: pw.FontWeight.bold, color: _brand)),
      pw.SizedBox(height: 4),
      pw.Text('${r.childName} · ${r.periodLabel} · generado $generated',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
      pw.SizedBox(height: 16),
      pw.Row(children: [
        _summary('Tiempo total de práctica',
            formatPracticeDuration(r.totalPractice)),
        pw.SizedBox(width: 12),
        _summary('Sesiones', '${r.totalSessions}'),
        pw.SizedBox(width: 12),
        _summary('Fonemas dominados',
            '${r.masteredCount} de ${r.phonemes.length}'),
      ]),
      pw.SizedBox(height: 20),
      pw.Text('Progreso por fonema',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...r.phonemes.map(_bar),
      pw.SizedBox(height: 20),
      pw.TableHelper.fromTextArray(
        headers: ['Fonema', 'Dominio', 'Nivel', 'Sesiones'],
        data: [
          for (final p in r.phonemes)
            [p.phoneme, '${p.mastery} %', p.level.label, '${p.sessions}'],
        ],
        headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _brand),
        cellAlignment: pw.Alignment.centerLeft,
      ),
    ],
  ));
  return doc.save();
}

pw.Widget _summary(String label, String value) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

pw.Widget _bar(PhonemeProgress p) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 24,
          child: pw.Text(p.phoneme,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          child: pw.Stack(children: [
            pw.Container(height: 14, color: PdfColors.grey200),
            pw.LayoutBuilder(
              builder: (ctx, c) => pw.Container(
                height: 14,
                width: c!.maxWidth * p.mastery / 100,
                color: _levelColor(p.level),
              ),
            ),
          ]),
        ),
        pw.SizedBox(
          width: 44,
          child: pw.Text('${p.mastery} %', textAlign: pw.TextAlign.right),
        ),
      ]),
    );
