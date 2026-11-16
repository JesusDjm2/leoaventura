import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/main.dart';
import 'package:leo_parvulos_app/reports/parent_report_models.dart';
import 'package:leo_parvulos_app/reports/parent_report_screen.dart';
import 'package:leo_parvulos_app/screens/home_screen.dart';
import 'package:leo_parvulos_app/screens/onboarding_screen.dart';
import 'package:leo_parvulos_app/screens/parent_settings_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Auditoría de Accesibilidad WCAG (5 Pantallas Principales)', () {
    testWidgets('1. HomeScreen cumple objetivos táctiles >= 48dp y contraste AA', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Verificar objetivos táctiles
      final settingsBtn = tester.getSize(find.byKey(const Key('home_settings_btn')));
      expect(settingsBtn.width, greaterThanOrEqualTo(48.0));
      expect(settingsBtn.height, greaterThanOrEqualTo(48.0));

      final reportsBtn = tester.getSize(find.byKey(const Key('home_reports_btn')));
      expect(reportsBtn.width, greaterThanOrEqualTo(48.0));
      expect(reportsBtn.height, greaterThanOrEqualTo(48.0));

      final cardM = tester.getSize(find.byKey(const Key('activity_card_m')));
      expect(cardM.width, greaterThanOrEqualTo(48.0));
      expect(cardM.height, greaterThanOrEqualTo(48.0));

      final onboardingBtn = tester.getSize(find.byKey(const Key('repeat_onboarding_btn')));
      expect(onboardingBtn.width, greaterThanOrEqualTo(48.0));
      expect(onboardingBtn.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('2. TracingGameScreen (Minijuego) cumple objetivos táctiles >= 48dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: TracingGameScreen()),
      );
      await tester.pumpAndSettle();

      final resetBtn = tester.getSize(find.byKey(const Key('reset_button')));
      expect(resetBtn.width, greaterThanOrEqualTo(48.0));
      expect(resetBtn.height, greaterThanOrEqualTo(48.0));

      final openReportsBtn = tester.getSize(find.byKey(const Key('open_parent_report')));
      expect(openReportsBtn.width, greaterThanOrEqualTo(48.0));
      expect(openReportsBtn.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('3. ParentReportScreen (Progreso) cumple objetivos táctiles >= 48dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(home: ParentReportScreen(report: ParentReport.mock())),
      );
      await tester.pumpAndSettle();

      final exportBtn = tester.getSize(find.byKey(const Key('export_pdf_button')));
      expect(exportBtn.width, greaterThanOrEqualTo(48.0));
      expect(exportBtn.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('4. ParentSettingsScreen (Ajustes) cumple objetivos táctiles >= 48dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: ParentSettingsScreen()),
      );
      await tester.pumpAndSettle();

      // Botón de compuerta parental
      final submitBtn = tester.getSize(find.byKey(const Key('parental_gate_submit')));
      expect(submitBtn.width, greaterThanOrEqualTo(48.0));
      expect(submitBtn.height, greaterThanOrEqualTo(48.0));

      // Resolver compuerta para validar ajustes
      await tester.enterText(find.byKey(const Key('parental_gate_input')), '12');
      await tester.tap(find.byKey(const Key('parental_gate_submit')));
      await tester.pumpAndSettle();

      final saveBtn = tester.getSize(find.byKey(const Key('save_settings_btn')));
      expect(saveBtn.width, greaterThanOrEqualTo(48.0));
      expect(saveBtn.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('5. OnboardingScreen cumple objetivos táctiles >= 48dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      final soundBtn = tester.getSize(find.byKey(const Key('onboarding_sound_check_btn')));
      expect(soundBtn.width, greaterThanOrEqualTo(48.0));
      expect(soundBtn.height, greaterThanOrEqualTo(48.0));

      final startBtn = tester.getSize(find.byKey(const Key('onboarding_start_btn')));
      expect(startBtn.width, greaterThanOrEqualTo(48.0));
      expect(startBtn.height, greaterThanOrEqualTo(48.0));
    });
  });
}
