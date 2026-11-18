import 'dart:convert';
import 'package:http/http.dart' as http;
import 'activity_model.dart';

/// Excepción lanzada cuando falla la descarga o el parseo del currículo dinámico.
class CurriculumFetchException implements Exception {
  final String message;
  final int? statusCode;

  const CurriculumFetchException(this.message, {this.statusCode});

  @override
  String toString() =>
      'CurriculumFetchException(statusCode: $statusCode, message: $message)';
}

/// Motor de carga de contenido dinámico que consume `GET /api/curriculum/levels`.
///
/// Diseñado offline-first: conserva en caché de memoria la última respuesta válida
/// para que los niños sigan jugando aunque se pierda temporalmente la conectividad.
class CurriculumService {
  final Uri baseUri;
  final http.Client _client;
  final bool _ownsClient;

  CurriculumResponse? _cachedResponse;

  CurriculumService({
    required this.baseUri,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  /// Último currículo descargado exitosamente en esta sesión.
  CurriculumResponse? get cachedCurriculum => _cachedResponse;

  /// Consume `GET /api/curriculum/levels` y parsea los niveles y actividades dinámicas.
  ///
  /// Si [forceRefresh] es `false` y ya existe una respuesta en caché, la devuelve
  /// de inmediato sin realizar llamadas de red.
  Future<CurriculumResponse> fetchLevels({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedResponse != null) {
      return _cachedResponse!;
    }

    final uri = baseUri.resolve('/api/curriculum/levels');
    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
    } catch (e) {
      if (_cachedResponse != null) {
        return _cachedResponse!;
      }
      throw CurriculumFetchException('Error de red al cargar el currículo: $e');
    }

    if (response.statusCode != 200) {
      throw CurriculumFetchException(
        'Respuesta inesperada del servidor al consultar niveles del currículo.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CurriculumFetchException('El cuerpo JSON del currículo no es un objeto válido.');
    }

    final parsed = CurriculumResponse.fromJson(decoded);
    _cachedResponse = parsed;
    return parsed;
  }

  /// Devuelve directamente la lista plana de todas las actividades del currículo.
  Future<List<ActivityModel>> fetchAllActivities({bool forceRefresh = false}) async {
    final curriculum = await fetchLevels(forceRefresh: forceRefresh);
    return curriculum.levels
        .expand((level) => level.activities)
        .toList(growable: false);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
