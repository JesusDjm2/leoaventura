import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'parent_report_models.dart';
import 'report_pdf_exporter.dart';

/// Colores del Design System Leoaventura con contraste AAA sobre blanco.
const _brand = AppColors.navy;
const _ink = AppColors.navy;
const _inkMuted = AppColors.textMuted;

Color levelColor(MasteryLevel l) => switch (l) {
      MasteryLevel.mastered => const Color(0xFF2E7D32),
      MasteryLevel.inProgress => const Color(0xFFB26A00),
      MasteryLevel.initial => const Color(0xFFC62828),
    };

/// Panel de padres/docentes: progreso por fonema, tiempo de práctica y
/// exportación a PDF.
class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({
    super.key,
    required this.report,
    this.exporter = const PrintingReportPdfExporter(),
  });

  static const routeName = '/reportes';

  final ParentReport report;
  final ReportPdfExporter exporter;

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    // El botón no se deshabilita (el estilo deshabilitado bajaría el contraste);
    // se ignoran pulsaciones repetidas mientras se genera.
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.exporter.export(widget.report);
      messenger.showSnackBar(
        const SnackBar(content: Text('Reporte PDF generado')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Panel de Padres y Docentes',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final summary = _SummaryCards(report: r, vertical: wide);
          final chart = _PhonemeChartCard(report: r);
          final exportButton = _ExportButton(
            exporting: _exporting,
            onPressed: _export,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(report: r),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                summary,
                                const SizedBox(height: 16),
                                exportButton,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: chart),
                        ],
                      )
                    else ...[
                      summary,
                      const SizedBox(height: 16),
                      chart,
                      const SizedBox(height: 16),
                      exportButton,
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report});
  final ParentReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          child: Text(
            report.childName.characters.first,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso de ${report.childName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              Text(
                report.periodLabel,
                style: const TextStyle(fontSize: 15, color: _inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.report, required this.vertical});
  final ParentReport report;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        key: const Key('total_practice_time'),
        icon: Icons.timer_outlined,
        label: 'Tiempo total de práctica',
        value: formatPracticeDuration(report.totalPractice),
      ),
      _StatCard(
        icon: Icons.event_repeat_rounded,
        label: 'Sesiones',
        value: '${report.totalSessions}',
      ),
      _StatCard(
        icon: Icons.emoji_events_outlined,
        label: 'Fonemas dominados',
        value: '${report.masteredCount} de ${report.phonemes.length}',
      ),
    ];
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in cards) ...[c, const SizedBox(height: 12)],
        ]..removeLast(),
      );
    }
    // Tiempo total a ancho completo; las otras dos a medias y de igual altura.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cards[0],
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD9DEE3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: _brand, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 14, color: _inkMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhonemeChartCard extends StatelessWidget {
  const _PhonemeChartCard({required this.report});
  final ParentReport report;

  @override
  Widget build(BuildContext context) {
    final phonemes = report.phonemes;
    final a11yLabel = 'Gráfico de barras de progreso por fonema. '
        '${phonemes.map((p) => '${p.phoneme}: ${p.mastery} por ciento, ${p.level.label}').join('; ')}.';

    return Card(
      key: const Key('phoneme_chart_card'),
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9DEE3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progreso por fonema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _ink,
              ),
            ),
            const Text(
              'Dominio promedio de cada sonido (0–100 %)',
              style: TextStyle(fontSize: 14, color: _inkMuted),
            ),
            const SizedBox(height: 20),
            if (phonemes.isEmpty)
              Container(
                key: const Key('empty_report_state'),
                constraints: const BoxConstraints(minHeight: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9DEE3)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 40, color: _inkMuted),
                    SizedBox(height: 10),
                    Text(
                      'Aún no hay sesiones registradas para este perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completa una letra con Leo y vuelve aquí para ver el progreso real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: _inkMuted),
                    ),
                  ],
                ),
              )
            else ...[
              if (report.totalSessions == 0) ...[
                Container(
                  key: const Key('starter_report_hint'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD9DEE3)),
                  ),
                  child: const Text(
                    'Aún no hay actividades completadas. Las barras subirán automáticamente al jugar con Leo.',
                    style: TextStyle(fontSize: 13, color: _inkMuted),
                  ),
                ),
              ],
              Semantics(
              container: true,
              label: a11yLabel,
              excludeSemantics: true,
              child: SizedBox(
                key: const Key('phoneme_bar_chart'),
                height: 260,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => _ink,
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          '${phonemes[group.x].phoneme}: ${rod.toY.round()} %',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE3E7EB),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 40,
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${v.toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              phonemes[v.toInt()].phoneme,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < phonemes.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: phonemes[i].mastery.toDouble(),
                              color: levelColor(phonemes[i].level),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: const Color(0xFFF1F3F5),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                for (final l in MasteryLevel.values.reversed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: levelColor(l),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.label,
                        style: const TextStyle(fontSize: 14, color: _ink),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.exporting, required this.onPressed});
  final bool exporting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const Key('export_pdf_button'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: exporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(exporting ? 'Generando PDF…' : 'Exportar PDF'),
    );
  }
}
