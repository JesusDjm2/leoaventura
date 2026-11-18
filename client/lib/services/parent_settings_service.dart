import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../observability/observability.dart';
import 'session_storage.dart';

/// Estado persistente de Ajustes Parentales y Seguridad (Sprint A — Paso 4).
///
/// Sincroniza el consentimiento de privacidad directamente con [SafeCrashReporter]
/// y expone la configuración de audio y velocidad de voz a [ParvuloTtsService].
class ParentSettingsState {
  static const String _storageKey = 'leoaventura_parent_settings_v1';

  static SessionStorage _storage = createPlatformSessionStorage();
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool highContrast = false;
  static bool audioFeedback = true;
  static String voiceSpeed = 'Normal'; // 'Lenta' | 'Normal' | 'Rápida'
  static int dailyLimitMinutes = 20;
  static bool crashReportingConsent = false;

  @visibleForTesting
  static void setStorageForTesting(SessionStorage storage) {
    _storage = storage;
  }

  /// Velocidad numérica para la síntesis de voz en español según preferencia parental.
  static double get speechRate => switch (voiceSpeed) {
        'Lenta' => 0.72,
        'Rápida' => 1.04,
        _ => 0.88,
      };

  static void reset() {
    highContrast = false;
    audioFeedback = true;
    voiceSpeed = 'Normal';
    dailyLimitMinutes = 20;
    crashReportingConsent = false;
    SafeCrashReporter.instance.setPrivacyConsent(false);
    revision.value++;
  }

  static Future<void> save() async {
    SafeCrashReporter.instance.setPrivacyConsent(crashReportingConsent);
    revision.value++;
    final payload = jsonEncode({
      'high_contrast': highContrast,
      'audio_feedback': audioFeedback,
      'voice_speed': voiceSpeed,
      'daily_limit_minutes': dailyLimitMinutes,
      'crash_reporting_consent': crashReportingConsent,
    });
    await _storage.write(_storageKey, payload);
  }

  static Future<bool> hydrate() async {
    try {
      final raw = await _storage.read(_storageKey);
      if (raw == null || raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;

      highContrast = (decoded['high_contrast'] as bool?) ?? false;
      audioFeedback = (decoded['audio_feedback'] as bool?) ?? true;
      final savedSpeed = (decoded['voice_speed'] as String?) ?? 'Normal';
      voiceSpeed = const {'Lenta', 'Normal', 'Rápida'}.contains(savedSpeed)
          ? savedSpeed
          : 'Normal';
      final savedLimit = (decoded['daily_limit_minutes'] as num?)?.toInt() ?? 20;
      dailyLimitMinutes = savedLimit.clamp(10, 60);
      crashReportingConsent =
          (decoded['crash_reporting_consent'] as bool?) ?? false;

      SafeCrashReporter.instance.setPrivacyConsent(crashReportingConsent);
      revision.value++;
      return true;
    } catch (_) {
      return false;
    }
  }
}
