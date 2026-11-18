import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Capa de celebración ligera que lanza 3 estrellas doradas en trayectoria curva
/// hacia el marcador superior derecho al completar un minijuego (650ms, 60fps).
///
/// Nunca bloquea toques (`IgnorePointer`) y respeta `prefers-reduced-motion`.
class FlyingStarsOverlay extends StatefulWidget {
  /// Incrementar este contador dispara un nuevo vuelo de estrellas.
  final int triggerCount;

  const FlyingStarsOverlay({
    super.key,
    required this.triggerCount,
  });

  @override
  State<FlyingStarsOverlay> createState() => _FlyingStarsOverlayState();
}

class _FlyingStarsOverlayState extends State<FlyingStarsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didUpdateWidget(covariant FlyingStarsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCount > oldWidget.triggerCount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating && _controller.value == 0.0) {
            return const SizedBox.shrink();
          }
          if (_controller.isCompleted) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final target = Offset(w - 46, 14);

              const starts = [
                Offset(0.42, 0.52),
                Offset(0.50, 0.46),
                Offset(0.58, 0.52),
              ];

              return Stack(
                children: List.generate(starts.length, (i) {
                  final delay = i * 0.10;
                  final localT = ((_controller.value - delay) / (1.0 - delay))
                      .clamp(0.0, 1.0);
                  final curved = Curves.easeInOutCubic.transform(localT);

                  final p0 = Offset(starts[i].dx * w, starts[i].dy * h);
                  final control = Offset(
                    (p0.dx + target.dx) * 0.5 + (i - 1) * 55,
                    math.min(p0.dy, target.dy) - 80,
                  );

                  // Curva Bézier cuadrática hacia el marcador de estrellas
                  final inv = 1.0 - curved;
                  final pos = Offset(
                    inv * inv * p0.dx +
                        2 * inv * curved * control.dx +
                        curved * curved * target.dx,
                    inv * inv * p0.dy +
                        2 * inv * curved * control.dy +
                        curved * curved * target.dy,
                  );

                  final scale = localT < 0.25
                      ? 0.6 + (localT / 0.25) * 0.7
                      : (1.3 - (localT - 0.25) * 0.85).clamp(0.45, 1.3);
                  final opacity = localT > 0.85
                      ? ((1.0 - localT) / 0.15).clamp(0.0, 1.0)
                      : 1.0;

                  return Positioned(
                    left: pos.dx - 18,
                    top: pos.dy - 18,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: curved * math.pi * 1.5,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.star_rounded,
                            size: 36,
                            color: Colors.amber,
                            shadows: [
                              Shadow(
                                color: Color(0x55E07B18),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}
