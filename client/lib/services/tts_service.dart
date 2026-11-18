import 'dart:async';
import 'package:flutter/widgets.dart';
import 'bundled_clip_player.dart';
import 'parent_settings_service.dart';
import 'speech_synthesizer.dart';

/// Interfaz del servicio de audio y síntesis de voz (TTS) para el minijuego pedagógico.
abstract class TtsService {
  Future<void> speak(String text);
  List<String> get audioLogs;
  void clearLogs();
}

/// Extensión opcional para servicios capaces de reproducir clips humanos grabados
/// (`assets/audio/v1/...`) antes de recurrir a síntesis de voz.
abstract interface class ClipAwareTtsService implements TtsService {
  Future<void> playClip(String? clipId, {String? fallbackText});
  Future<void> stop();
}

/// Conveniencia retrocompatible: cualquier [TtsService] puede invocar [playClip]
/// sin romper mocks existentes en pruebas.
extension TtsServiceClipPlayback on TtsService {
  Future<void> playClip(String? clipId, {String? fallbackText}) {
    if (this is ClipAwareTtsService) {
      return (this as ClipAwareTtsService).playClip(
        clipId,
        fallbackText: fallbackText,
      );
    }
    if (fallbackText != null && fallbackText.isNotEmpty) {
      return speak(fallbackText);
    }
    if (clipId != null && clipId.isNotEmpty) {
      return speak(clipId);
    }
    return Future<void>.value();
  }
}

/// Servicio híbrido de audio real para párvulos (Sprint A — Paso 2):
/// 1. **Prioridad 1 (Grabación humana):** Si el `clipId` existe en
///    `assets/audio/v1/manifest.json` (`fonema_a`, `fonema_m`, `fonema_p`, `fonema_s`,
///    `instruccion_traza_letra` o futuras grabaciones), lo reproduce con `just_audio`.
/// 2. **Prioridad 2 (Voz hablada en español):** Para instrucciones, sílabas o fonemas
///    pendientes de grabación, usa síntesis de voz (`SpeechSynthesizer`, Web Speech API
///    en navegador) para que las 20 letras tengan sonido real desde hoy.
class ParvuloTtsService implements ClipAwareTtsService {
  static ParvuloTtsService? _sharedInstance;

  /// Instancia compartida para toda la app viva (evita crear múltiples reproductores).
  static ParvuloTtsService get shared => _sharedInstance ??= ParvuloTtsService();

  final ClipAudioPlayer _clipPlayer;
  final SpeechSynthesizer _synthesizer;
  final bool _enableLiveOutput;
  final List<String> _logs = [];

  ParvuloTtsService({
    ClipAudioPlayer? clipPlayer,
    SpeechSynthesizer? synthesizer,
    bool? enableLiveOutput,
  })  : _clipPlayer = clipPlayer ?? BundledClipAudioPlayer(),
        _synthesizer = synthesizer ?? createPlatformSpeechSynthesizer(),
        _enableLiveOutput = enableLiveOutput ??
            (clipPlayer != null ||
                synthesizer != null ||
                !_isRunningInWidgetTest());

  static bool _isRunningInWidgetTest() {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  List<String> get audioLogs => List.unmodifiable(_logs);

  @override
  Future<void> speak(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    _logs.add(cleaned);
    debugPrint('[AudioTTS] Fonema/Instrucción reproducida: "$cleaned"');

    if (!_enableLiveOutput || !ParentSettingsState.audioFeedback) return;

    await _clipPlayer.stop();
    await _synthesizer.speak(
      cleaned,
      rate: ParentSettingsState.speechRate,
    );
  }

  @override
  Future<void> playClip(String? clipId, {String? fallbackText}) async {
    final normalizedClip = clipId?.trim();
    final fallback = fallbackText?.trim();

    if (fallback != null && fallback.isNotEmpty) {
      _logs.add(fallback);
    } else if (normalizedClip != null && normalizedClip.isNotEmpty) {
      _logs.add(normalizedClip);
    }

    if (!_enableLiveOutput || !ParentSettingsState.audioFeedback) return;

    if (normalizedClip != null && normalizedClip.isNotEmpty) {
      await _clipPlayer.ensureInitialized();
      if (_clipPlayer.hasClip(normalizedClip)) {
        await _synthesizer.stop();
        debugPrint('[AudioClip] Reproduciendo grabación humana: "$normalizedClip"');
        final played = await _clipPlayer.playClip(normalizedClip);
        if (played) return;
      }
    }

    if (fallback != null && fallback.isNotEmpty) {
      debugPrint('[AudioTTS] Fallback hablado: "$fallback"');
      await _synthesizer.speak(
        fallback,
        rate: ParentSettingsState.speechRate,
      );
    }
  }

  @override
  Future<void> stop() async {
    if (!_enableLiveOutput) return;
    await _clipPlayer.stop();
    await _synthesizer.stop();
  }

  @override
  void clearLogs() {
    _logs.clear();
  }
}
