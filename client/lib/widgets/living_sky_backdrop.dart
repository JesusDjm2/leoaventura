import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fondo vivo y sereno de cielo para la pantalla de Inicio (Paquete 2).
///
/// Renderiza nubes traslúcidas flotando suavemente y un sol cálido con
/// respiración muy sutil en GPU (`RepaintBoundary` + `CustomPainter`),
/// sin distraer de las letras y respetando `prefers-reduced-motion`.
class LivingSkyBackdrop extends StatefulWidget {
  final bool? forceAnimate;

  const LivingSkyBackdrop({super.key, this.forceAnimate});

  @override
  State<LivingSkyBackdrop> createState() => _LivingSkyBackdropState();
}

class _LivingSkyBackdropState extends State<LivingSkyBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    );
    final shouldAnimate = widget.forceAnimate ?? !_isWidgetTest;
    if (shouldAnimate) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _LivingSkyPainter(progress: _controller.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _LivingSkyPainter extends CustomPainter {
  final double progress;

  _LivingSkyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sol cálido suave en la esquina superior derecha
    final sunPulse = 1.0 + math.sin(progress * math.pi * 4) * 0.05;
    final sunCenter = Offset(size.width - 54, 48);
    canvas.drawCircle(
      sunCenter,
      54 * sunPulse,
      Paint()..color = AppColors.brandOrange.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      sunCenter,
      34 * sunPulse,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.28),
    );

    // 2. Tres nubes suaves moviéndose lentamente en capas de paralaje
    _drawCloud(
      canvas,
      Offset(_wrapX(size.width, progress * 1.0 + 0.12), 78),
      scale: 1.05,
      opacity: 0.55,
    );
    _drawCloud(
      canvas,
      Offset(_wrapX(size.width, progress * 0.72 + 0.58), 185),
      scale: 0.82,
      opacity: 0.42,
    );
    _drawCloud(
      canvas,
      Offset(_wrapX(size.width, progress * 0.50 + 0.85), 340),
      scale: 0.92,
      opacity: 0.34,
    );
  }

  double _wrapX(double width, double phase) {
    final normalized = phase % 1.0;
    return -120 + normalized * (width + 240);
  }

  void _drawCloud(
    Canvas canvas,
    Offset center, {
    required double scale,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, 10 * scale),
          width: 96 * scale,
          height: 30 * scale,
        ),
        Radius.circular(20 * scale),
      ),
      paint,
    );
    canvas.drawCircle(center + Offset(-22 * scale, 2 * scale), 20 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, -6 * scale), 26 * scale, paint);
    canvas.drawCircle(center + Offset(28 * scale, 4 * scale), 18 * scale, paint);
  }

  @override
  bool shouldRepaint(covariant _LivingSkyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
