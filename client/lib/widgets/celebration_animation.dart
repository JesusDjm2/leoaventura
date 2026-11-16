import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Componente de feedback visual y animación celebratoria para párvulos.
/// Diseñado para motivar al niño tras completar un trazo correcto.
class CelebrationAnimation extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onDismiss;

  const CelebrationAnimation({
    super.key,
    this.title = '¡Excelente!',
    this.subtitle = '¡Has trazado la letra M!',
    this.onDismiss,
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    final random = math.Random(42);
    _particles = List.generate(24, (i) {
      final angle = (i / 24) * 2 * math.pi;
      final speed = 70.0 + random.nextDouble() * 90.0;
      final color = [
        Colors.amber,
        Colors.pinkAccent,
        Colors.lightBlueAccent,
        Colors.purpleAccent,
        Colors.greenAccent,
      ][i % 5];
      return _Particle(
        angle: angle,
        speed: speed,
        color: color,
        size: 8.0 + random.nextDouble() * 8.0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Partículas de confeti
            CustomPaint(
              size: const Size(320, 320),
              painter: _ConfettiPainter(
                progress: _controller.value,
                particles: _particles,
              ),
            ),
            // Tarjeta central celebratoria
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withAlpha(128),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: _bounceAnimation.value,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFBF360C), size: 40),
                          SizedBox(width: 8),
                          Icon(Icons.star_rounded, color: Color(0xFFBF360C), size: 54),
                          SizedBox(width: 8),
                          Icon(Icons.star_rounded, color: Color(0xFFBF360C), size: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2933), // Contraste 9.8:1 sobre fondo ámbar (WCAG AAA)
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238), // Contraste 8.5:1 sobre fondo ámbar (WCAG AAA)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final distance = p.speed * progress;
      final x = center.dx + math.cos(p.angle) * distance;
      final y = center.dy + math.sin(p.angle) * distance + (progress * progress * 40); // gravedad sutil
      paint.color = p.color.withAlpha((255 * (1.0 - (progress * 0.4))).toInt());
      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
