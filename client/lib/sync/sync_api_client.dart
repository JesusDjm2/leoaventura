import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error HTTP o de transporte al sincronizar un lote.
class SyncException implements Exception {
  SyncException(this.message, {this.statusCode});

  final String message;

  /// null = fallo de red / timeout (sin respuesta del servidor).
  final int? statusCode;

  /// Fallos transitorios que se reintentan con backoff:
  /// red caída, timeout, 401 (token renovable), 408, 429 y 5xx.
  /// 403 y 422 son permanentes: reenviar el mismo lote no cambiaría nada.
  bool get isRetryable {
    final c = statusCode;
    if (c == null) return true;
    return c == 401 || c == 408 || c == 429 || c >= 500;
  }

  @override
  String toString() =>
      'SyncException(${statusCode ?? 'network'}): $message';
}

/// Cliente de `POST /api/sync/progress`.
class SyncApiClient {
  SyncApiClient({
    required this.baseUrl,
    required this.httpClient,
    this.tokenProvider,
    this.timeout = const Duration(seconds: 20),
  });

  final Uri baseUrl;
  final http.Client httpClient;
  final Future<String?> Function()? tokenProvider;
  final Duration timeout;

  Future<Map<String, dynamic>> pushProgress(
      List<Map<String, dynamic>> events) async {
    final token = await tokenProvider?.call();
    final http.Response res;
    try {
      res = await httpClient
          .post(
            baseUrl.resolve('/api/sync/progress'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'events': events}),
          )
          .timeout(timeout);
    } catch (e) {
      throw SyncException(e.toString());
    }
    if (res.statusCode == 200) {
      final body = res.body.isEmpty ? null : jsonDecode(res.body);
      return body is Map<String, dynamic> ? body : const {};
    }
    throw SyncException(res.body, statusCode: res.statusCode);
  }
}
