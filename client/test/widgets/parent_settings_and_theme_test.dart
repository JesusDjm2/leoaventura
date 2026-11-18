import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leo_parvulos_app/observability/observability.dart';
import 'package:leo_parvulos_app/reports/parent_report_models.dart';
import 'package:leo_parvulos_app/reports/parent_report_screen.dart';
import 'package:leo_parvulos_app/screens/onboarding_screen.dart';
import 'package:leo_parvulos_app/screens/parent_settings_screen.dart';
import 'package:leo_parvulos_app/services/parent_settings_service.dart';
import 'package:leo_parvulos_app/services/session_storage.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';

void main() {
  late InMemorySessionStorage storage;

  setUp(() {
    storage = InMemorySessionStorage();
    ParentSettingsState.setStorageForTesting(storage);
    ParentSettingsState.reset();
    SafeCrashReporter.instance = SafeCrashReporter(
      transport: TestCrashPanelTransport(),
      initialPrivacyConsent: false,
    );
  });

  group('Sprint A Paso 4: Parental Gate Aleatorio, Persistencia y Tema Unificado', () {
    testWidgets('Parental Gate rechaza respuesta incorrecta, regenera operación y persiste consentimiento COPPA',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ParentSettingsScreen(random: math.Random(7)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Validar fondo oficial AppColors.sky
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.sky);

      // 2. Respuesta incorrecta muestra error y regenera operación
      await tester.enterText(find.byKey(const Key('parental_gate_input')), '999');
      await tester.tap(find.byKey(const Key('parental_gate_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('parental_gate_error')), findsOneWidget);

      // 3. Resolver la nueva operación generada
      final questionText = tester
          .widget<Text>(find.byKey(const Key('parental_gate_question')))
          .data!;
      final match = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(questionText)!;
      final expected = int.parse(match.group(1)!) * int.parse(match.group(2)!);

      await tester.enterText(
        find.byKey(const Key('parental_gate_input')),
        expected.toString(),
      );
      await tester.tap(find.byKey(const Key('parental_gate_submit')));
      await tester.pumpAndSettle();

      // 4. Activar consentimiento de diagnóstico anónimo y guardar
      expect(SafeCrashReporter.instance.hasPrivacyConsent, isFalse);
      await tester.ensureVisible(find.byKey(const Key('switch_privacy_consent')));
      await tester.tap(find.byKey(const Key('switch_privacy_consent')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(SafeCrashReporter.instance.hasPrivacyConsent, isTrue);

      // 5. Simular reinicio y validar hidratación persistida
      ParentSettingsState.reset();
      expect(SafeCrashReporter.instance.hasPrivacyConsent, isFalse);

      final hydrated = await ParentSettingsState.hydrate();
      expect(hydrated, isTrue);
      expect(ParentSettingsState.crashReportingConsent, isTrue);
      expect(SafeCrashReporter.instance.hasPrivacyConsent, isTrue);
    });

    testWidgets('ParentReportScreen y OnboardingScreen usan la paleta oficial AppColors.sky', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ParentReportScreen(report: ParentReport.mock()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.sky,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.sky,
      );
    });
  });
}
