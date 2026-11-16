import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Estados de la máquina de estados interactiva de la mascota León Leo.
enum MascotState {
  idle,
  talking,
  celebrating,
}

/// Widget de la mascota animada León Leo con sincronización de audio.
/// Implementa una máquina de estados para los modos: Idle, Hablando (con movimiento labial)
/// y Celebrando (con salto, estrellas y confeti).
class LeoMascot extends StatefulWidget {
  final MascotState state;
  final double size;
  final bool isAudioPlaying;
  final String? spokenText;

  const LeoMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = 180.0,
    this.isAudioPlaying = false,
    this.spokenText,
  });

  @override
  State<LeoMascot> createState() => LeoMascotState();
}

class LeoMascotState extends State<LeoMascot> with TickerProviderStateMixin {
  late AnimationController _mouthController;
  late AnimationController _bounceController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    // Controlador para sincronización labial cuando habla
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // Controlador de salto celebratorio
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Parpadeo suave en reposo
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _updateState(widget.state, widget.isAudioPlaying);
  }

  @override
  void didUpdateWidget(covariant LeoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.isAudioPlaying != widget.isAudioPlaying) {
      _updateState(widget.state, widget.isAudioPlaying);
    }
  }

  void _updateState(MascotState state, bool isAudioPlaying) {
    final effectiveState = isAudioPlaying ? MascotState.talking : state;

    if (effectiveState == MascotState.talking) {
      _mouthController.repeat(reverse: true);
      _bounceController.stop();
    } else if (effectiveState == MascotState.celebrating) {
      _mouthController.stop();
      _mouthController.value = 0.8; // Boca abierta sonriente
      _bounceController.repeat(reverse: true);
    } else {
      _mouthController.stop();
      _mouthController.value = 0.0;
      _bounceController.stop();
    }
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _bounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveState = widget.isAudioPlaying ? MascotState.talking : widget.state;

    return AnimatedBuilder(
      animation: Listenable.merge([_mouthController, _bounceController, _blinkController]),
      builder: (context, child) {
        final bounceOffset = effectiveState == MascotState.celebrating
            ? math.sin(_bounceController.value * math.pi) * 14.0
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -bounceOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              key: Key('mascot_canvas_${effectiveState.name}'),
              painter: _LeoMascotPainter(
                state: effectiveState,
                mouthProgress: _mouthController.value,
                celebrationProgress: _bounceController.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeoMascotPainter extends CustomPainter {
  final MascotState state;
  final double mouthProgress;
  final double celebrationProgress;

  _LeoMascotPainter({
    required this.state,
    required this.mouthProgress,
    required this.celebrationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    // 1. Melena exuberante dorada del León Leo
    final manePaint = Paint()
      ..color = const Color(0xFFF57C00)
      ..style = PaintingStyle.fill;

    const petals = 12;
    for (int i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * math.pi;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (radius * 0.85),
        center.dy + math.sin(angle) * (radius * 0.85),
      );
      canvas.drawCircle(petalCenter, radius * 0.32, manePaint);
    }

    // 2. Orejas del león
    final earOuterPaint = Paint()..color = const Color(0xFFFFB300);
    final earInnerPaint = Paint()..color = const Color(0xFFFFCC80);
    final earRadius = radius * 0.28;

    // Oreja izquierda
    final leftEarCenter = Offset(center.dx - radius * 0.65, center.dy - radius * 0.65);
    canvas.drawCircle(leftEarCenter, earRadius, earOuterPaint);
    canvas.drawCircle(leftEarCenter, earRadius * 0.55, earInnerPaint);

    // Oreja derecha
    final rightEarCenter = Offset(center.dx + radius * 0.65, center.dy - radius * 0.65);
    canvas.drawCircle(rightEarCenter, earRadius, earOuterPaint);
    canvas.drawCircle(rightEarCenter, earRadius * 0.55, earInnerPaint);

    // 3. Cabeza y rostro del cachorro
    final facePaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(center, radius * 0.72, facePaint);

    // 4. Hocico
    final muzzlePaint = Paint()..color = const Color(0xFFFFF9C4);
    final muzzleCenter = Offset(center.dx, center.dy + radius * 0.20);
    canvas.drawOval(
      Rect.fromCenter(center: muzzleCenter, width: radius * 0.80, height: radius * 0.50),
      muzzlePaint,
    );

    // 5. Nariz triangular marrón
    final nosePaint = Paint()..color = const Color(0xFF4E342E);
    final nosePath = Path()
      ..moveTo(center.dx - radius * 0.12, muzzleCenter.dy - radius * 0.12)
      ..lineTo(center.dx + radius * 0.12, muzzleCenter.dy - radius * 0.12)
      ..lineTo(center.dx, muzzleCenter.dy + radius * 0.05)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // 6. Ojos según el estado
    final eyePaint = Paint()..color = const Color(0xFF263238);
    final leftEye = Offset(center.dx - radius * 0.28, center.dy - radius * 0.12);
    final rightEye = Offset(center.dx + radius * 0.28, center.dy - radius * 0.12);

    if (state == MascotState.celebrating) {
      // Ojos en arco sonrientes de felicidad (^^)
      final eyeArcPaint = Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..addArc(Rect.fromCircle(center: leftEye, radius: radius * 0.14), math.pi * 1.1, math.pi * 0.8);
      final rightArc = Path()
        ..addArc(Rect.fromCircle(center: rightEye, radius: radius * 0.14), math.pi * 1.1, math.pi * 0.8);

      canvas.drawPath(leftArc, eyeArcPaint);
      canvas.drawPath(rightArc, eyeArcPaint);
    } else {
      // Ojos redondos abiertos con brillo
      canvas.drawCircle(leftEye, radius * 0.11, eyePaint);
      canvas.drawCircle(rightEye, radius * 0.11, eyePaint);

      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(leftEye.dx - radius * 0.03, leftEye.dy - radius * 0.03), radius * 0.04, shinePaint);
      canvas.drawCircle(Offset(rightEye.dx - radius * 0.03, rightEye.dy - radius * 0.03), radius * 0.04, shinePaint);
    }

    // 7. Boca animada sincronizada
    final mouthPaint = Paint()
      ..color = const Color(0xFFC2185B)
      ..style = PaintingStyle.fill;

    final mouthStroke = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;

    final mouthCenter = Offset(center.dx, muzzleCenter.dy + radius * 0.16);

    if (state == MascotState.talking) {
      // Boca abriéndose y cerrándose rítmicamente con el audio
      final openHeight = radius * 0.10 + (mouthProgress * radius * 0.25);
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: radius * 0.32,
        height: openHeight,
      );
      canvas.drawOval(mouthRect, mouthPaint);
      canvas.drawOval(mouthRect, mouthStroke);

      // Dientecito lindo de cachorro
      final toothPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(mouthCenter.dx - radius * 0.05, mouthCenter.dy - openHeight / 2, radius * 0.10, radius * 0.07),
          const Radius.circular(4),
        ),
        toothPaint,
      );
    } else if (state == MascotState.celebrating) {
      // Boca abierta de alegría máxima
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: radius * 0.40,
        height: radius * 0.32,
      );
      canvas.drawOval(mouthRect, mouthPaint);
      canvas.drawOval(mouthRect, mouthStroke);

      // Estrellitas flotantes de celebración
      _drawStar(canvas, Offset(center.dx - radius * 0.85, center.dy - radius * 0.60), 16, Colors.amber);
      _drawStar(canvas, Offset(center.dx + radius * 0.85, center.dy - radius * 0.60), 16, Colors.amber);
      _drawStar(canvas, Offset(center.dx, center.dy - radius * 1.05), 20, const Color(0xFFFFD700));
    } else {
      // Sonrisa amable cerrada
      final smilePath = Path()
        ..moveTo(mouthCenter.dx - radius * 0.16, mouthCenter.dy)
        ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + radius * 0.14, mouthCenter.dx + radius * 0.16, mouthCenter.dy);
      canvas.drawPath(smilePath, mouthStroke);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? size : size / 2;
      final angle = (i / (points * 2)) * 2 * math.pi - (math.pi / 2);
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeoMascotPainter oldDelegate) => true;
}
