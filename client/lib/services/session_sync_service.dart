import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../reports/parent_report_models.dart';
import 'session_storage.dart';

/// Modelo ligero de progreso sincronizado desde `GET /api/progress`.
class SyncedProgressEntry {
  final int childId;
  final String childName;
  final String activityId;
  final int score;
  final int stars;
  final String? updatedAt;

  const SyncedProgressEntry({
    required this.childId,
    required this.childName,
    required this.activityId,
    required this.score,
    required this.stars,
    this.updatedAt,
  });

  factory SyncedProgressEntry.fromJson(Map<String, dynamic> json) {
    return SyncedProgressEntry(
      childId: (json['child_id'] as num?)?.toInt() ?? 0,
      childName: (json['child_name'] as String?) ?? '',
      activityId: (json['activity_id'] as String?) ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'child_name': childName,
        'activity_id': activityId,
        'score': score,
        'stars': stars,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

/// Estado de sesión, persistencia local y sincronización en vivo con Laravel
/// (`/api/sync/progress`, `/api/progress` y `/api/children/{child}/report`).
class AppSessionState {
  static const String _storageKey = 'leoaventura_session_v1';

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static SessionStorage _storage = createPlatformSessionStorage();

  /// Notificador reactivo para que pantallas como `HomeScreen` se actualicen
  /// automáticamente tras hidratar sesión o sincronizar progreso.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static String? authToken;
  static int? activeChildId;
  static String activeChildName = 'Mateo';
  static String activeAvatarKey = 'leo_lion';
  static int totalStars = 0;
  static List<SyncedProgressEntry> syncedProgress = const [];
  static final Set<String> _localCompletedActivities = <String>{};
  static bool lastSyncSucceeded = false;

  /// Permite sustituir el backend de persistencia en tests.
  @visibleForTesting
  static void setStorageForTesting(SessionStorage storage) {
    _storage = storage;
  }

  static void _bumpRevision() {
    revision.value++;
  }

  /// Resuelve la URL base del backend (en emulador Android `10.0.2.2` apunta al host local).
  static String resolveApiBaseUrl([String? override]) {
    if (override != null && override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return defaultApiBaseUrl.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return defaultApiBaseUrl;
  }

  static void reset() {
    authToken = null;
    activeChildId = null;
    activeChildName = 'Mateo';
    activeAvatarKey = 'leo_lion';
    totalStars = 0;
    syncedProgress = const [];
    _localCompletedActivities.clear();
    lastSyncSucceeded = false;
    _bumpRevision();
  }

  /// Cierra sesión limpiando tanto memoria como almacenamiento persistente.
  static Future<void> logout() async {
    reset();
    await _storage.delete(_storageKey);
  }

  /// Elimina permanentemente la cuenta parental y sus datos asociados (`DELETE /api/user`).
  static Future<({bool ok, String message})> deleteAccount({
    required String password,
    String? apiBaseUrl,
    http.Client? client,
  }) async {
    final token = authToken;
    if (token == null || token.isEmpty) {
      return (ok: false, message: 'No hay una sesión familiar activa.');
    }

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    final baseUrl = resolveApiBaseUrl(apiBaseUrl);

    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await logout();
        return (
          ok: true,
          message: 'Cuenta y datos eliminados permanentemente.',
        );
      }

      String msg = 'No se pudo eliminar la cuenta (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          msg = decoded['message'] as String;
        }
      } catch (_) {}
      return (ok: false, message: msg);
    } catch (_) {
      return (
        ok: false,
        message: 'No se pudo conectar con el servidor para eliminar la cuenta.',
      );
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  /// Persiste la sesión actual y el progreso local en el almacenamiento de la plataforma.
  static Future<void> persist() async {
    final payload = jsonEncode({
      'auth_token': authToken,
      'active_child_id': activeChildId,
      'active_child_name': activeChildName,
      'active_avatar_key': activeAvatarKey,
      'total_stars': totalStars,
      'local_completed': _localCompletedActivities.toList(growable: false),
      'synced_progress': syncedProgress.map((e) => e.toJson()).toList(growable: false),
    });
    await _storage.write(_storageKey, payload);
  }

  /// Restaura la sesión y progreso guardados al iniciar o recargar la app.
  static Future<bool> hydrate() async {
    try {
      final raw = await _storage.read(_storageKey);
      if (raw == null || raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;

      authToken = decoded['auth_token'] as String?;
      activeChildId = (decoded['active_child_id'] as num?)?.toInt();
      final savedName = (decoded['active_child_name'] as String?)?.trim();
      if (savedName != null && savedName.isNotEmpty) {
        activeChildName = savedName;
      }
      final savedAvatar = (decoded['active_avatar_key'] as String?)?.trim();
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        activeAvatarKey = savedAvatar;
      }
      totalStars = (decoded['total_stars'] as num?)?.toInt() ?? 0;

      _localCompletedActivities
        ..clear()
        ..addAll(
          ((decoded['local_completed'] as List?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty),
        );

      final rawSynced = (decoded['synced_progress'] as List?) ?? const [];
      syncedProgress = rawSynced
          .whereType<Map>()
          .map((m) => SyncedProgressEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);

      _bumpRevision();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isActivityCompleted(String activityId) {
    return _localCompletedActivities.contains(activityId) ||
        syncedProgress.any((e) => e.activityId == activityId);
  }

  /// Registra una actividad completada localmente (modo invitado u offline)
  /// y la persiste para reflejar progreso inmediato en el mapa de niveles.
  static void recordLocalCompletion({
    required String activityId,
    int stars = 3,
  }) {
    final isNew = _localCompletedActivities.add(activityId);
    if (isNew && !syncedProgress.any((e) => e.activityId == activityId)) {
      totalStars += stars;
    }
    _bumpRevision();
    unawaited(persist());
  }

  /// Envía la finalización de un minijuego al backend Laravel (`POST /api/sync/progress`).
  static Future<bool> syncActivityCompletion({
    required String activityId,
    int score = 100,
    int stars = 3,
    Map<String, dynamic>? metadata,
    String? apiBaseUrl,
    http.Client? client,
  }) async {
    final token = authToken;
    final childId = activeChildId;
    if (token == null || token.isEmpty || childId == null) {
      await persist();
      return false;
    }

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    final baseUrl = resolveApiBaseUrl(apiBaseUrl);

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/sync/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'events': [
            {
              'child_id': childId,
              'activity_id': activityId,
              'score': score,
              'stars': stars,
              'updated_at': nowIso,
              'deleted_at': null,
              if (metadata != null) 'metadata': metadata,
            },
          ],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        lastSyncSucceeded = true;
        await fetchSyncedProgress(apiBaseUrl: baseUrl, client: httpClient);
        return true;
      }
      await persist();
      return false;
    } catch (_) {
      await persist();
      return false;
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  /// Consulta `GET /api/progress` con el Bearer token del padre e hidrata el estado local.
  static Future<bool> fetchSyncedProgress({
    String? apiBaseUrl,
    http.Client? client,
  }) async {
    final token = authToken;
    if (token == null || token.isEmpty) {
      return false;
    }

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    final baseUrl = resolveApiBaseUrl(apiBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/progress'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final rawChildren = (decoded['children'] as List?) ?? const [];
        if (rawChildren.isNotEmpty) {
          final firstChild = rawChildren.first as Map<String, dynamic>;
          activeChildId = (firstChild['id'] as num?)?.toInt();
          activeChildName = (firstChild['name'] as String?) ?? activeChildName;
          activeAvatarKey = (firstChild['avatar_key'] as String?) ?? activeAvatarKey;
        }

        final rawProgress = (decoded['progress'] as List?) ?? const [];
        syncedProgress = rawProgress
            .whereType<Map>()
            .map((m) => SyncedProgressEntry.fromJson(Map<String, dynamic>.from(m)))
            .toList(growable: false);
        totalStars = (decoded['total_stars'] as num?)?.toInt() ??
            syncedProgress.fold<int>(0, (sum, item) => sum + item.stars);
        lastSyncSucceeded = true;
        _bumpRevision();
        await persist();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  /// Construye un [ParentReport] real a partir del progreso local/sincronizado actual
  /// (usado cuando el usuario juega en modo invitado o sin conexión).
  static ParentReport buildLocalReport({DateTime? now}) {
    final buckets = <String, List<int>>{};

    for (final entry in syncedProgress) {
      final letter = _extractLetterFromActivityId(entry.activityId);
      if (letter == null) continue;
      buckets.putIfAbsent(letter, () => []).add(entry.score.clamp(0, 100));
    }

    for (final activityId in _localCompletedActivities) {
      if (syncedProgress.any((e) => e.activityId == activityId)) continue;
      final letter = _extractLetterFromActivityId(activityId);
      if (letter == null) continue;
      buckets.putIfAbsent(letter, () => []).add(100);
    }

    final phonemes = buckets.isNotEmpty
        ? buckets.entries.map((entry) {
            final scores = entry.value;
            final avg = scores.fold<int>(0, (a, b) => a + b) / scores.length;
            return PhonemeProgress(
              phoneme: entry.key,
              mastery: avg.round().clamp(0, 100),
              sessions: scores.length,
            );
          }).toList(growable: false)
        : const [
            PhonemeProgress(phoneme: 'A', mastery: 0, sessions: 0),
            PhonemeProgress(phoneme: 'E', mastery: 0, sessions: 0),
            PhonemeProgress(phoneme: 'I', mastery: 0, sessions: 0),
            PhonemeProgress(phoneme: 'M', mastery: 0, sessions: 0),
            PhonemeProgress(phoneme: 'P', mastery: 0, sessions: 0),
            PhonemeProgress(phoneme: 'S', mastery: 0, sessions: 0),
          ];

    final totalSessions = phonemes.fold<int>(0, (a, p) => a + p.sessions);
    return ParentReport(
      childName: activeChildName,
      periodLabel: authToken != null ? 'Progreso acumulado' : 'Sesión local',
      totalPractice: Duration(minutes: totalSessions * 3),
      phonemes: phonemes,
      generatedAt: now ?? DateTime.now(),
    );
  }

  /// Obtiene el reporte real desde Laravel (`GET /api/children/{child}/report`),
  /// con respaldo automático en [buildLocalReport] si no hay sesión o red.
  static Future<ParentReport> fetchParentReport({
    int? childId,
    String? apiBaseUrl,
    http.Client? client,
  }) async {
    final token = authToken;
    final targetChildId = childId ?? activeChildId;

    if (token == null || token.isEmpty || targetChildId == null) {
      return buildLocalReport();
    }

    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    final baseUrl = resolveApiBaseUrl(apiBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/children/$targetChildId/report'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ParentReport.fromJson(decoded);
        }
      }
      return buildLocalReport();
    } catch (_) {
      return buildLocalReport();
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  static String? _extractLetterFromActivityId(String activityId) {
    final match = RegExp(r'^act_([a-zñ]+)_', caseSensitive: false)
        .firstMatch(activityId.trim());
    if (match == null) return null;
    final slug = match.group(1)!.toLowerCase();
    if (slug == 'enie') return 'Ñ';
    return slug.toUpperCase();
  }
}
