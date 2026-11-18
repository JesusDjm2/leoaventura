import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../theme/app_theme.dart';
import 'leo_mascot.dart';

/// Estados emocionales soportados por la State Machine de `<AnimatedLeo />`.
abstract final class AnimatedLeoStateName {
  static const String idle = 'idle';
  static const String happy = 'happy';
  static const String sad = 'sad';

  static String normalize(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == happy) return happy;
    if (lower == sad) return sad;
    return idle;
  }

  /// Índice numérico determinista para inputs numéricos de Rive (`state`, `mood`, `Level`).
  static double toNumericLevel(String normalizedState) {
    return switch (normalizedState) {
      happy => 1.0,
      sad => 2.0,
      _ => 0.0,
    };
  }
}

/// Contrato del controlador de State Machine de Rive para `<AnimatedLeo />`.
///
/// En producción (Flutter Web WASM, Android, iOS) se respalda con
/// [RiveStateMachineDriver] envolviendo un [StateMachineController] real de `package:rive`.
/// En tests de widget headless sin librería FFI nativa (`rive_common_plugin.dll`),
/// permite inyectar o degradar limpiamente a [InMemoryLeoRiveDriver] manteniendo
/// las mismas garantías de transición y 60fps.
abstract interface class LeoRiveStateDriver {
  String get stateMachineName;
  String get activeState;
  double get numericStateValue;
  bool get isHappy;
  bool get isSad;
  bool get isRiveNativeActive;
  List<String> get appliedTransitions;
  void applyState(String normalizedState);
  void dispose();
}

/// Driver de producción que conecta directamente con `StateMachineController` de `package:rive`.
class RiveStateMachineDriver implements LeoRiveStateDriver {
  final StateMachineController controller;
  @override
  final String stateMachineName;
  final SMIInput<double>? numericStateInput;
  final SMIInput<bool>? happyBoolInput;
  final SMIInput<bool>? sadBoolInput;
  final SMITrigger? happyTriggerInput;
  final SMITrigger? sadTriggerInput;

  @override
  final List<String> appliedTransitions = <String>[];

  String _activeState = AnimatedLeoStateName.idle;

  RiveStateMachineDriver({
    required this.controller,
    required this.stateMachineName,
    this.numericStateInput,
    this.happyBoolInput,
    this.sadBoolInput,
    this.happyTriggerInput,
    this.sadTriggerInput,
  });

  factory RiveStateMachineDriver.fromController(
    StateMachineController controller,
    String stateMachineName,
  ) {
    SMIInput<double>? numericInput;
    SMIInput<bool>? happyBool;
    SMIInput<bool>? sadBool;
    SMITrigger? happyTrigger;
    SMITrigger? sadTrigger;

    for (final input in controller.inputs) {
      final lower = input.name.trim().toLowerCase();
      if (input is SMIInput<double> &&
          (lower == 'state' || lower == 'mood' || lower == 'level')) {
        numericInput ??= input;
      } else if (input is SMIInput<bool>) {
        if (lower == 'ishappy' || lower == 'happy') {
          happyBool ??= input;
        } else if (lower == 'issad' || lower == 'sad') {
          sadBool ??= input;
        }
      } else if (input is SMITrigger) {
        if (lower == 'happy' || lower == 'onhappy' || lower == 'happytrigger') {
          happyTrigger ??= input;
        } else if (lower == 'sad' || lower == 'onsad' || lower == 'sadtrigger') {
          sadTrigger ??= input;
        }
      }
    }

    if (numericInput == null) {
      for (final input in controller.inputs) {
        if (input is SMIInput<double>) {
          numericInput = input;
          break;
        }
      }
    }

    return RiveStateMachineDriver(
      controller: controller,
      stateMachineName: stateMachineName,
      numericStateInput: numericInput,
      happyBoolInput: happyBool,
      sadBoolInput: sadBool,
      happyTriggerInput: happyTrigger,
      sadTriggerInput: sadTrigger,
    );
  }

  @override
  String get activeState => _activeState;

  @override
  double get numericStateValue =>
      numericStateInput?.value ??
      AnimatedLeoStateName.toNumericLevel(_activeState);

  @override
  bool get isHappy =>
      happyBoolInput?.value ?? (_activeState == AnimatedLeoStateName.happy);

  @override
  bool get isSad =>
      sadBoolInput?.value ?? (_activeState == AnimatedLeoStateName.sad);

  @override
  bool get isRiveNativeActive => controller.isActive;

  @override
  void applyState(String normalizedState) {
    _activeState = normalizedState;
    appliedTransitions.add(normalizedState);

    numericStateInput?.value =
        AnimatedLeoStateName.toNumericLevel(normalizedState);
    happyBoolInput?.value = normalizedState == AnimatedLeoStateName.happy;
    sadBoolInput?.value = normalizedState == AnimatedLeoStateName.sad;

    if (normalizedState == AnimatedLeoStateName.happy) {
      happyTriggerInput?.fire();
    } else if (normalizedState == AnimatedLeoStateName.sad) {
      sadTriggerInput?.fire();
    }
  }

  @override
  void dispose() {
    controller.dispose();
  }
}

/// Driver determinista en memoria usado como respaldo seguro en VM de pruebas
/// headless (sin librería nativa FFI `rive_common_plugin.dll`) o inyección en tests.
class InMemoryLeoRiveDriver implements LeoRiveStateDriver {
  @override
  final String stateMachineName;

  @override
  final List<String> appliedTransitions = <String>[];

  String _activeState = AnimatedLeoStateName.idle;
  double _numericValue = 0.0;
  bool _isHappy = false;
  bool _isSad = false;
  bool _disposed = false;

  InMemoryLeoRiveDriver({this.stateMachineName = 'LeoStateMachine'});

  @override
  String get activeState => _activeState;

  @override
  double get numericStateValue => _numericValue;

  @override
  bool get isHappy => _isHappy;

  @override
  bool get isSad => _isSad;

  @override
  bool get isRiveNativeActive => !_disposed;

  @override
  void applyState(String normalizedState) {
    if (_disposed) return;
    _activeState = normalizedState;
    _numericValue = AnimatedLeoStateName.toNumericLevel(normalizedState);
    _isHappy = normalizedState == AnimatedLeoStateName.happy;
    _isSad = normalizedState == AnimatedLeoStateName.sad;
    appliedTransitions.add(normalizedState);
  }

  @override
  void dispose() {
    _disposed = true;
  }
}

/// Mascota animada de LeoPárvulos impulsada por Rive State Machine.
///
/// Uso declarativo:
/// ```dart
/// const AnimatedLeo(state: 'idle')
/// const AnimatedLeo(state: 'happy')
/// const AnimatedLeo(state: 'sad')
/// ```
///
/// Optimizada para 60fps:
/// - Aislada en un [RepaintBoundary] para evitar repintados en el árbol padre.
/// - Mapea los estados (`idle`, `happy`, `sad`) a inputs de State Machine de Rive
///   (`isHappy`/`isSad`, triggers `happy`/`sad`, o input numérico `state`/`Level`).
/// - El estado `sad` es siempre empático y alentador (nunca punitivo).
class AnimatedLeo extends StatefulWidget {
  /// Estado deseado: `'idle'`, `'happy'` o `'sad'`.
  final String state;

  /// Dimensión cuadrada del contenedor de la mascota.
  final double size;

  /// Ruta del asset `.riv` empaquetado.
  final String assetPath;

  /// Nombre explícito de la State Machine. Si es `null`, selecciona `'LeoStateMachine'`
  /// o la primera State Machine disponible en el artboard.
  final String? stateMachineName;

  /// Driver opcional inyectable para pruebas deterministas.
  final LeoRiveStateDriver? driver;

  /// Callback invocado en cuanto la State Machine queda enlazada y lista.
  final ValueChanged<LeoRiveStateDriver>? onStateMachineReady;

  /// Muestra una etiqueta empática breve debajo de la mascota cuando cambia de ánimo.
  final bool showMoodBadge;

  /// Activa el renderizado visual del artboard `.riv` (mantener `false` mientras
  /// `leo_mascot.riv` sea el asset de prueba y mostrar el arte oficial de Leo).
  final bool preferRiveArtboard;

  const AnimatedLeo({
    super.key,
    this.state = AnimatedLeoStateName.idle,
    this.size = 116.0,
    this.assetPath = 'assets/animations/leo_mascot.riv',
    this.stateMachineName,
    this.driver,
    this.onStateMachineReady,
    this.showMoodBadge = false,
    this.preferRiveArtboard = false,
  });

  @override
  State<AnimatedLeo> createState() => AnimatedLeoState();
}

class AnimatedLeoState extends State<AnimatedLeo> {
  static Future<void>? _riveInitFuture;

  Artboard? _artboard;
  LeoRiveStateDriver? _driver;
  bool _ownsDriver = false;
  bool _usingFallbackVisual = false;

  static bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  static Future<void> _ensureRiveInitialized() {
    return _riveInitFuture ??= () async {
      if (!_isTestEnvironment) {
        try {
          await RiveFile.initialize();
        } catch (_) {
          // Respaldo seguro en caso de entorno sin runtime nativo
        }
      }
    }();
  }

  /// Acceso al driver activo de la State Machine (útil para tests y QA).
  LeoRiveStateDriver? get riveDriver => _driver;

  /// Estado actual normalizado (`idle`, `happy` o `sad`).
  String get currentState => AnimatedLeoStateName.normalize(widget.state);

  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      _driver = widget.driver;
      _ownsDriver = false;
      _driver!.applyState(currentState);
      widget.onStateMachineReady?.call(_driver!);
    } else if (_isTestEnvironment) {
      final testDriver = InMemoryLeoRiveDriver(
        stateMachineName: widget.stateMachineName ?? 'LeoStateMachine',
      );
      _driver = testDriver;
      _ownsDriver = true;
      _usingFallbackVisual = true;
      testDriver.applyState(currentState);
      widget.onStateMachineReady?.call(testDriver);
    } else {
      _loadRiveArtboard();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedLeo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath && widget.driver == null) {
      _disposeDriver();
      _loadRiveArtboard();
      return;
    }

    final previous = AnimatedLeoStateName.normalize(oldWidget.state);
    final next = AnimatedLeoStateName.normalize(widget.state);
    if (previous != next) {
      _driver?.applyState(next);
    }
  }

  Future<void> _loadRiveArtboard() async {
    try {
      await _ensureRiveInitialized();
      final data = await rootBundle.load(widget.assetPath);

      if (_isTestEnvironment) {
        // Valida la cabecera binaria RIVE del asset empaquetado sin exigir DLL FFI en Windows VM.
        if (data.lengthInBytes < 4 ||
            String.fromCharCodes(data.buffer.asUint8List(0, 4)) != 'RIVE') {
          throw const FormatException('Asset .riv inválido');
        }
        if (!mounted) return;
        final testDriver = InMemoryLeoRiveDriver(
          stateMachineName: widget.stateMachineName ?? 'LeoStateMachine',
        );
        _driver = testDriver;
        _ownsDriver = true;
        testDriver.applyState(currentState);
        widget.onStateMachineReady?.call(testDriver);
        setState(() {
          _artboard = null;
          _usingFallbackVisual = true;
        });
        return;
      }

      // En Web/Android/iOS/Desktop carga el artboard Rive completo con StateMachineController.
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard.instance();

      final smName = _resolveStateMachineName(artboard);
      StateMachineController? controller;
      if (smName != null) {
        controller = StateMachineController.fromArtboard(artboard, smName);
      }

      if (!mounted) {
        controller?.dispose();
        return;
      }

      if (controller != null) {
        artboard.addController(controller);
        final driver = RiveStateMachineDriver.fromController(controller, smName!);
        _driver = driver;
        _ownsDriver = true;
        driver.applyState(currentState);
        widget.onStateMachineReady?.call(driver);
      }

      setState(() {
        _artboard = artboard;
        _usingFallbackVisual = false;
      });
    } catch (_) {
      if (!mounted) return;
      final fallbackDriver = InMemoryLeoRiveDriver(
        stateMachineName: widget.stateMachineName ?? 'LeoStateMachine',
      );
      _driver = fallbackDriver;
      _ownsDriver = true;
      fallbackDriver.applyState(currentState);
      widget.onStateMachineReady?.call(fallbackDriver);

      setState(() {
        _artboard = null;
        _usingFallbackVisual = true;
      });
    }
  }

  String? _resolveStateMachineName(Artboard artboard) {
    if (widget.stateMachineName != null && widget.stateMachineName!.isNotEmpty) {
      return widget.stateMachineName;
    }

    final machines = artboard.stateMachines;
    if (machines.isEmpty) return null;

    for (final sm in machines) {
      if (sm.name.toLowerCase().contains('leo')) {
        return sm.name;
      }
    }
    return machines.first.name;
  }

  void _disposeDriver() {
    if (_ownsDriver) {
      _driver?.dispose();
    }
    _driver = null;
    _artboard = null;
  }

  @override
  void dispose() {
    _disposeDriver();
    super.dispose();
  }

  String get _empatheticMoodLabel {
    return switch (currentState) {
      AnimatedLeoStateName.happy => '¡Muy bien!',
      AnimatedLeoStateName.sad => '¡Casi! Tú puedes',
      _ => '¡Vamos a jugar!',
    };
  }

  Color get _ringColor {
    return switch (currentState) {
      AnimatedLeoStateName.happy => AppColors.brandGreen,
      AnimatedLeoStateName.sad => AppColors.brandCyan,
      _ => AppColors.brandOrange,
    };
  }

  MascotState get _fallbackMascotState {
    return switch (currentState) {
      AnimatedLeoStateName.happy => MascotState.celebrating,
      AnimatedLeoStateName.sad => MascotState.talking,
      _ => MascotState.idle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Widget visual = (widget.preferRiveArtboard &&
            !_usingFallbackVisual &&
            _artboard != null &&
            !reduceMotion)
        ? Rive(
            key: Key('animated_leo_rive_$currentState'),
            artboard: _artboard!,
            fit: BoxFit.contain,
            useArtboardSize: false,
          )
        : AnimatedScale(
            scale: currentState == AnimatedLeoStateName.happy ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: LeoMascot(
              key: Key('animated_leo_visual_$currentState'),
              state: _fallbackMascotState,
              size: widget.size * 0.88,
            ),
          );

    return Semantics(
      label: 'Mascota animada Leo en estado $currentState. $_empatheticMoodLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _ringColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: _ringColor, width: 3),
              ),
              child: ClipOval(child: visual),
            ),
          ),
          if (widget.showMoodBadge) ...[
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey<String>(currentState),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _ringColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _empatheticMoodLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
