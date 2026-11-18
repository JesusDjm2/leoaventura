import 'package:flutter/material.dart';

/// Transición de entrada suave desde abajo usando [SlideTransition] + [FadeTransition].
///
/// - Animación 100% acelerada por GPU (`transform` + `opacity`).
/// - Impulsada por una [Animation<double>] maestra con [Interval] para escalonamiento
///   (stagger) limpio sin timers pendientes.
/// - Nunca bloquea toques del usuario durante la animación de entrada.
/// - Respeta `prefers-reduced-motion`.
class SlideInEntrance extends StatelessWidget {
  final Animation<double> parentAnimation;
  final double beginInterval;
  final double endInterval;
  final Offset beginOffset;
  final Widget child;

  const SlideInEntrance({
    super.key,
    required this.parentAnimation,
    required this.child,
    this.beginInterval = 0.0,
    this.endInterval = 0.6,
    this.beginOffset = const Offset(0, 0.16),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: parentAnimation,
      curve: Interval(beginInterval, endInterval, curve: Curves.easeOutCubic),
    );

    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}
