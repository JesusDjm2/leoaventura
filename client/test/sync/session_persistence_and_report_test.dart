import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leo_parvulos_app/reports/parent_report_models.dart';
import 'package:leo_parvulos_app/reports/parent_report_screen.dart';
import 'package:leo_parvulos_app/services/session_storage.dart';
import 'package:leo_parvulos_app/services/session_sync_service.dart';

void main() {
  late InMemorySessionStorage storage;

  setUp(() {
    storage = InMemorySessionStorage();
    AppSessionState.setStorageForTesting(storage);
    AppSessionState.reset();
  });

  group('Sprint A Paso 3: Persistencia de Sesión y Reportes Parentales Reales', () {
    test('persist() + hydrate() restaura sesión, niño activo, estrellas y progreso tras recarga', () async {
      AppSessionState.authToken = 'sanctum_token_demo';
      AppSessionState.activeChildId = 42;
      AppSessionState.activeChildName = 'Valeria';
      AppSessionState.activeAvatarKey = 'leo_lion';
      AppSessionState.recordLocalCompletion(activityId: 'act_s_tracing', stars: 3);
      AppSessionState.recordLocalCompletion(activityId: 'act_s_syllable_builder', stars: 3);
      await AppSessionState.persist();

      // Simular cierre / recarga limpiando memoria RAM
      AppSessionState.reset();
      expect(AppSessionState.authToken, isNull);
      expect(AppSessionState.activeChildName, 'Mateo');
      expect(AppSessionState.totalStars, 0);

      // Restaurar desde almacenamiento persistente
      final restored = await AppSessionState.hydrate();
      expect(restored, isTrue);
      expect(AppSessionState.authToken, 'sanctum_token_demo');
      expect(AppSessionState.activeChildId, 42);
      expect(AppSessionState.activeChildName, 'Valeria');
      expect(AppSessionState.totalStars, 6);
      expect(AppSessionState.isActivityCompleted('act_s_tracing'), isTrue);
      expect(AppSessionState.isActivityCompleted('act_s_syllable_builder'), isTrue);
    });

    test('fetchParentReport() consume GET /api/children/{child}/report y construye ParentReport real', () async {
      AppSessionState.authToken = 'token_parent_1';
      AppSessionState.activeChildId = 7;
      AppSessionState.activeChildName = 'Valeria';

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/children/7/report');
        expect(request.headers['Authorization'], 'Bearer token_parent_1');
        return http.Response(
          jsonEncode({
            'child_id': 7,
            'child_name': 'Valeria',
            'period_label': 'Progreso acumulado',
            'total_practice_minutes': 18,
            'total_stars': 9,
            'total_sessions': 3,
            'generated_at': '2026-11-18T02:15:00Z',
            'phonemes': [
              {'phoneme': 'M', 'mastery': 95, 'sessions': 2, 'stars': 6},
              {'phoneme': 'Ñ', 'mastery': 80, 'sessions': 1, 'stars': 3},
            ],
          }),
          200,
        );
      });

      final report = await AppSessionState.fetchParentReport(
        apiBaseUrl: 'http://127.0.0.1:8000',
        client: mockClient,
      );

      expect(report.childName, 'Valeria');
      expect(report.totalPractice, const Duration(minutes: 18));
      expect(report.totalSessions, 3);
      expect(report.masteredCount, 2);
      expect(report.phonemes.map((p) => p.phoneme).toList(), ['M', 'Ñ']);
    });

    testWidgets('ParentReportScreen muestra estado inicial sin overflow y estado vacío explícito', (tester) async {
      final starterReport = AppSessionState.buildLocalReport();
      expect(starterReport.totalSessions, 0);
      expect(starterReport.phonemes, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentReportScreen(report: starterReport),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('starter_report_hint')), findsOneWidget);
      expect(tester.takeException(), isNull);

      final explicitEmpty = ParentReport(
        childName: 'Mateo',
        periodLabel: 'Sesión local',
        totalPractice: Duration.zero,
        phonemes: const [],
        generatedAt: DateTime(2026, 11, 18),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ParentReportScreen(report: explicitEmpty),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty_report_state')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
