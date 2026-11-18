import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leo_parvulos_app/observability/observability.dart';

void main() {
  group('Fase 17: Observabilidad, Scrubber de PII y Consentimiento Parental', () {
    test('simula excepción con nombre y email y verifica que el scrubber los reemplaza por [REDACTED] antes del envío', () async {
      final sentryTestPanel = TestCrashPanelTransport();
      final reporter = SafeCrashReporter(
        transport: sentryTestPanel,
        environment: 'test',
        initialPrivacyConsent: true,
      );

      final exception = StateError(
        'Error al cargar progreso de nombre: Mateo Ramírez con email papa.mateo@correo.com',
      );

      final sent = await reporter.captureException(
        exception,
        StackTrace.current,
        extra: {
          'child_name': 'Mateo Ramírez',
          'email': 'papa.mateo@correo.com',
          'device_id': 'android-xyz-123',
          'ip_address': '10.0.2.15',
          'activity_code': 'act_s_tracing',
        },
        tags: {'minigame': 'tracing'},
      );

      // El panel en modo test recibió el reporte limpio
      expect(sent, isNotNull);
      expect(sentryTestPanel.receivedEvents, hasLength(1));

      final payload = sentryTestPanel.receivedEvents.first;
      final serialized = jsonEncode(payload);

      // Verificación estricta: cero PII en el payload enviado
      expect(serialized, isNot(contains('Mateo Ramírez')));
      expect(serialized, isNot(contains('papa.mateo@correo.com')));
      expect(serialized, isNot(contains('android-xyz-123')));
      expect(serialized, isNot(contains('10.0.2.15')));

      // Verificación de reemplazo explícito por [REDACTED]
      expect(payload['message'], contains('[REDACTED]'));
      final exceptionValues = (payload['exception'] as Map)['values'] as List;
      final exceptionValue = (exceptionValues.first as Map)['value'] as String;
      expect(exceptionValue, contains('nombre: [REDACTED]'));
      expect(exceptionValue, contains('email [REDACTED]'));

      final extra = payload['extra'] as Map<String, dynamic>;
      expect(extra['child_name'], '[REDACTED]');
      expect(extra['email'], '[REDACTED]');
      expect(extra['device_id'], '[REDACTED]');
      expect(extra['ip_address'], '[REDACTED]');

      // Los metadatos técnicos no personales permanecen útiles para depuración
      expect(extra['activity_code'], 'act_s_tracing');
      expect(payload.containsKey('user'), isFalse);
    });

    test('bloquea completamente los reportes mientras el usuario no acepte términos de privacidad', () async {
      final sentryTestPanel = TestCrashPanelTransport();
      final reporter = SafeCrashReporter(
        transport: sentryTestPanel,
        initialPrivacyConsent: false,
      );

      expect(reporter.hasPrivacyConsent, isFalse);

      // 1. Intento antes de aceptar términos -> bloqueado
      final blocked = await reporter.captureException(
        Exception('Fallo de red para Sofía López (sofia@correo.com)'),
        StackTrace.current,
      );
      expect(blocked, isNull);
      expect(sentryTestPanel.receivedEvents, isEmpty);

      // 2. El adulto acepta los términos de privacidad -> se envía limpio
      reporter.setPrivacyConsent(true);
      expect(reporter.hasPrivacyConsent, isTrue);

      final delivered = await reporter.captureException(
        Exception('Fallo de red para Sofía López (sofia@correo.com)'),
        StackTrace.current,
      );
      expect(delivered, isNotNull);
      expect(sentryTestPanel.receivedEvents, hasLength(1));
      final serialized = jsonEncode(sentryTestPanel.receivedEvents.first);
      expect(serialized, contains('[REDACTED]'));
      expect(serialized, isNot(contains('Sofía López')));
      expect(serialized, isNot(contains('sofia@correo.com')));

      // 3. Si el adulto revoca el consentimiento -> se detienen los envíos
      reporter.setPrivacyConsent(false);
      final afterRevoke = await reporter.captureException(
        Exception('Otro error técnico'),
        StackTrace.current,
      );
      expect(afterRevoke, isNull);
      expect(sentryTestPanel.receivedEvents, hasLength(1));
    });

    test('SentryHttpTransport envía el evento limpio a la API Store v7 de Sentry en modo test', () async {
      Map<String, dynamic>? receivedBody;
      String? authHeader;
      Uri? targetUri;

      final mockClient = MockClient((request) async {
        targetUri = request.url;
        authHeader = request.headers['X-Sentry-Auth'];
        receivedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"id":"sentry-evt-001"}', 200);
      });

      final transport = SentryHttpTransport(
        dsn: 'https://testkey99@sentry.leoparvulos.test/77',
        client: mockClient,
      );
      final reporter = SafeCrashReporter(
        transport: transport,
        initialPrivacyConsent: true,
      );

      await reporter.captureException(
        FormatException('Token inválido Bearer abc.def.ghi para name: Ana Torres ana@ejemplo.org'),
        StackTrace.current,
      );

      expect(targetUri.toString(), 'https://sentry.leoparvulos.test/api/77/store/');
      expect(authHeader, contains('sentry_key=testkey99'));
      expect(receivedBody, isNotNull);

      final bodyJson = jsonEncode(receivedBody);
      expect(bodyJson, contains('[REDACTED]'));
      expect(bodyJson, isNot(contains('Ana Torres')));
      expect(bodyJson, isNot(contains('ana@ejemplo.org')));
      expect(bodyJson, isNot(contains('abc.def.ghi')));
    });
  });
}
