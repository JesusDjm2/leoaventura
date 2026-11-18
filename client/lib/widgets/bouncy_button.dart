import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// Contenedor interactivo con efecto físico de rebote ("Juice") usando [AnimatedScale].
///
/// - Al presionar: se encoge suavemente un 5% (`pressedScale = 0.95`) en 90ms.
/// - Al soltar: rebota de vuelta a escala `1.0` en 150ms con curva elástica suave.
/// - Nunca bloquea ni retrasa la interacción: si envuelve un botón interno (`onTap == null`),
///   escucha el puntero mediante [Listener] sin competir en el GestureArena; si recibe [onTap],
///   lo dispara de inmediato al soltar.
/// - Respeta `prefers-reduced-motion` (`MediaQuery.maybeDisableAnimationsOf`).
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve pressCurve;
  final Curve releaseCurve;
  final bool enabled;
  final String? semanticsLabel;

  const BouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.pressDuration = const Duration(milliseconds: 90),
    this.releaseDuration = const Duration(milliseconds: 150),
    this.pressCurve = Curves.easeOutCubic,
    this.releaseCurve = Curves.easeOutBack,
    this.enabled = true,
    this.semanticsLabel,
  });

  @override
  State<BouncyButton> createState() => BouncyButtonState();
}

class BouncyButtonState extends State<BouncyButton> {
  bool _isPressed = false;

  /// Expuesto para verificación determinista en tests de widget.
  bool get isPressed => _isPressed;

  double get currentScale => _isPressed ? widget.pressedScale : 1.0;

  void _setPressed(bool pressed) {
    if (!widget.enabled || _isPressed == pressed) return;
    if (pressed) {
      HapticService.lightImpact();
    }
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final targetScale = (!widget.enabled || reduceMotion) ? 1.0 : currentScale;
    final duration = reduceMotion
        ? Duration.zero
        : (_isPressed ? widget.pressDuration : widget.releaseDuration);
    final curve = _isPressed ? widget.pressCurve : widget.releaseCurve;

    final animatedChild = AnimatedScale(
      scale: targetScale,
      duration: duration,
      curve: curve,
      alignment: Alignment.center,
      child: widget.child,
    );

    Widget interactive;
    if (widget.onTap != null) {
      interactive = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.enabled ? widget.onTap : null,
        child: animatedChild,
      );
    } else {
      // Observador pasivo: permite rebote físico alrededor de InkWell / PrimaryButton
      // sin interceptar ni retrasar el evento onTap del hijo.
      interactive = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: animatedChild,
      );
    }

    if (widget.semanticsLabel != null) {
      return Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.semanticsLabel,
        child: interactive,
      );
    }

    return interactive;
  }
}
