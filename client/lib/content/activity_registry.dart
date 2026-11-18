import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/letter_tracing.dart';
import '../widgets/sound_match_game.dart';
import '../widgets/syllable_builder_game.dart';
import '../widgets/word_reading_game.dart';
import 'activity_model.dart';

/// Constructor genérico para renderizar cualquier tipo de minijuego desde [ActivityModel].
typedef ActivityWidgetBuilder = Widget Function(
  BuildContext context,
  ActivityModel activity, {
  TtsService? ttsService,
  VoidCallback? onComplete,
});

/// Registro extensible de minijuegos (Principio Abierto/Cerrado - SOLID).
///
/// Permite añadir nuevos tipos de actividades (p. ej. `syllable_builder`,
/// `memory_pairs`, `phoneme_bingo`) simplemente llamando a [register] al
/// iniciar el módulo, sin modificar [ActivityModel], [DynamicActivityHost]
/// ni el núcleo de navegación de la app.
class ActivityRegistry {
  final Map<String, ActivityWidgetBuilder> _builders = {};

  ActivityRegistry();

  /// Crea una instancia precargada con los minijuegos nativos de LeoPárvulos.
  factory ActivityRegistry.withDefaults() {
    final registry = ActivityRegistry();
    registry.register(
      ActivityTypes.tracing,
      (context, activity, {ttsService, onComplete}) => LetterTracing.fromActivity(
        activity,
        ttsService: ttsService,
        onComplete: onComplete,
      ),
    );
    registry.register(
      ActivityTypes.soundMatch,
      (context, activity, {ttsService, onComplete}) => SoundMatchGame.fromActivity(
        activity,
        ttsService: ttsService,
        onComplete: onComplete,
      ),
    );
    registry.register(
      ActivityTypes.syllableBuilder,
      (context, activity, {ttsService, onComplete}) =>
          SyllableBuilderGame.fromActivity(
        activity,
        ttsService: ttsService,
        onComplete: onComplete,
      ),
    );
    registry.register(
      ActivityTypes.wordReading,
      (context, activity, {ttsService, onComplete}) =>
          WordReadingGame.fromActivity(
        activity,
        ttsService: ttsService,
        onComplete: onComplete,
      ),
    );
    return registry;
  }

  /// Registra o reemplaza el constructor visual asociado a un [type] del currículo.
  void register(String type, ActivityWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Indica si el motor cuenta con un constructor registrado para [type].
  bool supports(String type) => _builders.containsKey(type);

  /// Tipos de actividad actualmente registrados en el motor.
  Set<String> get registeredTypes => Set<String>.unmodifiable(_builders.keys);

  /// Construye el widget correspondiente a [activity], o un estado de respaldo
  /// seguro si el backend envía un tipo aún no soportado por esta versión de la app.
  Widget build(
    BuildContext context,
    ActivityModel activity, {
    TtsService? ttsService,
    VoidCallback? onComplete,
  }) {
    final builder = _builders[activity.type];
    if (builder == null) {
      return _UnsupportedActivityFallback(activity: activity);
    }
    return builder(
      context,
      activity,
      ttsService: ttsService,
      onComplete: onComplete,
    );
  }
}

/// Contenedor genérico que resuelve y renderiza dinámicamente cualquier actividad
/// a partir de un [ActivityModel] o directamente desde un JSON del servidor.
class DynamicActivityHost extends StatelessWidget {
  final ActivityModel activity;
  final ActivityRegistry? registry;
  final TtsService? ttsService;
  final VoidCallback? onComplete;

  const DynamicActivityHost({
    super.key,
    required this.activity,
    this.registry,
    this.ttsService,
    this.onComplete,
  });

  /// Conveniencia para inyectar directamente un JSON de actividad (útil en tests y deep-links).
  factory DynamicActivityHost.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    ActivityRegistry? registry,
    TtsService? ttsService,
    VoidCallback? onComplete,
  }) {
    return DynamicActivityHost(
      key: key,
      activity: ActivityModel.fromJson(json),
      registry: registry,
      ttsService: ttsService,
      onComplete: onComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRegistry = registry ?? ActivityRegistry.withDefaults();
    return effectiveRegistry.build(
      context,
      activity,
      ttsService: ttsService,
      onComplete: onComplete,
    );
  }
}

class _UnsupportedActivityFallback extends StatelessWidget {
  final ActivityModel activity;

  const _UnsupportedActivityFallback({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_off_rounded, size: 48, color: Color(0xFF4A7DB7)),
            const SizedBox(height: 12),
            Text(
              'Actualiza la app para jugar "${activity.title.isNotEmpty ? activity.title : activity.type}".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
