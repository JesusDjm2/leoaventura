import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'pii_scrubber.dart';

/// Contrato de transporte para el envío de reportes de error sanitizados.
abstract interface class CrashReportTransport {
  Future<bool> send(Map<String, dynamic> sentryPayload);
}

/// Panel de Sentry en modo test (en memoria) para auditoría determinista.
class TestCrashPanelTransport implements CrashReportTransport {
  final List<Map<String, dynamic>> receivedEvents = [];

  @override
  Future<bool> send(Map<String, dynamic> sentryPayload) async {
    receivedEvents.add(Map<String, dynamic>.unmodifiable(sentryPayload));
    return true;
  }

  void clear() => receivedEvents.clear();
}

/// Transporte HTTP compatible con la API Store v7 de Sentry.
///
/// No inicializa SDKs nativos de terceros antes del consentimiento parental.
class SentryHttpTransport implements CrashReportTransport {
  final String? dsn;
  final http.Client _client;
  final bool _ownsClient;

  SentryHttpTransport({
    required this.dsn,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  Future<bool> send(Map<String, dynamic> sentryPayload) async {
    final rawDsn = dsn?.trim();
    if (rawDsn == null || rawDsn.isEmpty) {
      return false;
    }

    final parsed = Uri.tryParse(rawDsn);
    if (parsed == null || parsed.host.isEmpty || parsed.userInfo.isEmpty) {
      return false;
    }

    final publicKey = parsed.userInfo.split(':').first;
    final projectId = parsed.pathSegments.isNotEmpty ? parsed.pathSegments.last : '';
    if (publicKey.isEmpty || projectId.isEmpty) {
      return false;
    }

    final endpoint = Uri(
      scheme: parsed.scheme.isNotEmpty ? parsed.scheme : 'https',
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: '/api/$projectId/store/',
    );

    try {
      final response = await _client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'X-Sentry-Auth':
              'Sentry sentry_version=7, sentry_client=leoparvulos-flutter/1.0, sentry_key=$publicKey',
        },
        body: jsonEncode(sentryPayload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Sistema de observabilidad y crash reporting seguro para LeoPárvulos (Fase 17).
///
/// Garantías de privacidad infantil (COPPA):
/// 1. **Consentimiento explícito:** `hasPrivacyConsent` inicia en `false`. Ningún
///    reporte se transmite mientras los padres no hayan aceptado los términos.
/// 2. **Filtro PII obligatorio (`beforeSend`):** Todo mensaje, traza, etiqueta y
///    contexto pasa por [PiiScrubber] sustituyendo cualquier dato personal por `[REDACTED]`.
class SafeCrashReporter {
  static final Random _random = Random();

  final CrashReportTransport transport;
  final PiiScrubber scrubber;
  final String environment;
  final String release;

  bool _hasPrivacyConsent;

  SafeCrashReporter({
    required this.transport,
    this.scrubber = const PiiScrubber(),
    this.environment = 'production',
    this.release = 'leo-parvulos-client@1.0.0',
    bool initialPrivacyConsent = false,
  }) : _hasPrivacyConsent = initialPrivacyConsent;

  /// Instancia compartida configurada al arranque de la app (sin consentimiento inicial).
  static SafeCrashReporter instance = SafeCrashReporter(
    transport: TestCrashPanelTransport(),
    environment: kReleaseMode ? 'production' : 'development',
    initialPrivacyConsent: false,
  );

  /// Indica si el adulto responsable aceptó los términos de privacidad.
  bool get hasPrivacyConsent => _hasPrivacyConsent;

  /// Actualiza el estado de consentimiento parental para telemetría de errores.
  void setPrivacyConsent(bool accepted) {
    _hasPrivacyConsent = accepted;
  }

  /// Captura y reporta una excepción si y solo si existe consentimiento de privacidad.
  ///
  /// Devuelve el payload limpio enviado (para inspección o auditoría) o `null`
  /// si el envío fue bloqueado por falta de consentimiento.
  Future<Map<String, dynamic>?> captureException(
    Object error,
    StackTrace? stackTrace, {
    Map<String, dynamic> extra = const {},
    Map<String, String> tags = const {},
    List<String> breadcrumbs = const [],
  }) async {
    if (!_hasPrivacyConsent) {
      return null;
    }

    final rawEvent = <String, dynamic>{
      'event_id': _generateEventId(),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': 'dart',
      'level': 'error',
      'environment': environment,
      'release': release,
      'message': error.toString(),
      'exception': {
        'values': [
          {
            'type': error.runtimeType.toString(),
            'value': error.toString(),
            if (stackTrace != null) 'stacktrace': stackTrace.toString(),
          },
        ],
      },
      'tags': tags,
      'extra': extra,
      if (breadcrumbs.isNotEmpty) 'breadcrumbs': breadcrumbs,
    };

    // beforeSend obligatorio: elimina cualquier PII y bloque `user`
    final cleanPayload = scrubber.scrubMap(rawEvent)..remove('user');

    final delivered = await transport.send(cleanPayload);
    return delivered ? cleanPayload : null;
  }

  /// Conecta los manejadores globales de errores de Flutter respetando la compuerta parental.
  void installGlobalHandlers() {
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_hasPrivacyConsent) {
        captureException(
          details.exception,
          details.stack,
          tags: {'source': 'flutter_error'},
        );
      }
      previousFlutterError?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (_hasPrivacyConsent) {
        captureException(
          error,
          stack,
          tags: {'source': 'platform_dispatcher'},
        );
      }
      return false;
    };
  }

  String _generateEventId() {
    const hex = '0123456789abcdef';
    return List.generate(32, (_) => hex[_random.nextInt(16)]).join();
  }
}
