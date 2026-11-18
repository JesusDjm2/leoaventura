import 'package:flutter/services.dart';

/// Contrato del controlador háptico para inyección y mocking en pruebas.
abstract interface class HapticController {
  /// Vibración ligera al presionar un botón o tarjeta (`HapticFeedback.lightImpact`).
  Future<void> lightImpact();

  /// Vibración moderada de éxito al completar una actividad (`HapticFeedback.mediumImpact`).
  Future<void> mediumImpact();

  /// Clic sutil para cambios de selección (`HapticFeedback.selectionClick`).
  Future<void> selectionClick();
}

/// Implementación nativa que delega en `HapticFeedback` de Flutter.
class PlatformHapticController implements HapticController {
  const PlatformHapticController();

  @override
  Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Plataformas sin motor háptico (Web/Desktop) ignoran silenciosamente.
    }
  }

  @override
  Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Plataformas sin motor háptico ignoran silenciosamente.
    }
  }

  @override
  Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Plataformas sin motor háptico ignoran silenciosamente.
    }
  }
}

/// Punto de acceso centralizado al controlador háptico de Leoaventura.
///
/// Permite sustituir [instance] por un mock determinista en tests de integración.
abstract final class HapticService {
  static HapticController instance = const PlatformHapticController();

  static Future<void> lightImpact() => instance.lightImpact();

  static Future<void> mediumImpact() => instance.mediumImpact();

  static Future<void> selectionClick() => instance.selectionClick();

  static void reset() {
    instance = const PlatformHapticController();
  }
}
