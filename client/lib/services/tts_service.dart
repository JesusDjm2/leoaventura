import 'dart:async';
import 'package:flutter/foundation.dart';

/// Interfaz del servicio de audio y síntesis de voz (TTS) para el minijuego pedagógico.
abstract class TtsService {
  Future<void> speak(String text);
  List<String> get audioLogs;
  void clearLogs();
}

/// Implementación por defecto con registro determinista de eventos de audio para párvulos.
class ParvuloTtsService implements TtsService {
  final List<String> _logs = [];

  @override
  List<String> get audioLogs => List.unmodifiable(_logs);

  @override
  Future<void> speak(String text) async {
    final logMessage = '[AudioTTS] Fonema/Instrucción reproducida: "$text"';
    _logs.add(text);
    debugPrint(logMessage);
    // En entornos nativos con altavoces activos puede delegar a flutter_tts
  }

  @override
  void clearLogs() {
    _logs.clear();
  }
}
