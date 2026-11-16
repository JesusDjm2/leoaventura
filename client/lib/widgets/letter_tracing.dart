import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import 'celebration_animation.dart';

/// Widget de trazado táctil para párvulos.
/// Muestra la letra guía, captura los trazos del niño, evalúa precisión y
/// provee retroalimentación visual (animación) y auditiva (TTS).
class LetterTracing extends StatefulWidget {
  final String letter;
  final VoidCallback? onComplete;
  final TtsService? ttsService;

  const LetterTracing({
    super.key,
    required this.letter,
    this.onComplete,
    this.ttsService,
  });

  @override
  State<LetterTracing> createState() => _LetterTracingState();
}

class _LetterTracingState extends State<LetterTracing> {
  late final TtsService _ttsService;

  final List<Offset> _userPoints = [];
  final Set<int> _hitCheckpoints = {};
  bool _isCompleted = false;

  // Checkpoints normalizados (0.0 a 1.0) para la letra 'm'
  static const List<Offset> normalizedCheckpointsM = [
    Offset(0.22, 0.35), // 1. Inicio trazo vertical izquierdo
    Offset(0.22, 0.55), // 2. Centro trazo vertical izquierdo
    Offset(0.22, 0.75), // 3. Base trazo vertical izquierdo
    Offset(0.36, 0.35), // 4. Cúspide del primer arco
    Offset(0.50, 0.55), // 5. Centro del segundo pilar
    Offset(0.50, 0.75), // 6. Base del segundo pilar
    Offset(0.64, 0.35), // 7. Cúspide del segundo arco
    Offset(0.78, 0.55), // 8. Centro del tercer pilar
    Offset(0.78, 0.75), // 9. Base final
  ];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttsService.speak('¡Hola! Traza la letra ${widget.letter.toUpperCase()} con tu dedito.');
    });
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    if (_isCompleted) return;
    _addPoint(details.localPosition, canvasSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_isCompleted) return;
    _addPoint(details.localPosition, canvasSize);
  }

  void _addPoint(Offset localPosition, Size canvasSize) {
    setState(() {
      _userPoints.add(localPosition);
    });

    _checkHitpoints(localPosition, canvasSize);
  }

  void _checkHitpoints(Offset point, Size canvasSize) {
    final checkpoints = normalizedCheckpointsM;
    final hitRadius = canvasSize.width * 0.16; // Margen adaptado para párvulos

    for (int i = 0; i < checkpoints.length; i++) {
      if (_hitCheckpoints.contains(i)) continue;

      final target = Offset(
        checkpoints[i].dx * canvasSize.width,
        checkpoints[i].dy * canvasSize.height,
      );

      final distance = (point - target).distance;
      if (distance <= hitRadius) {
        _hitCheckpoints.add(i);
      }
    }

    // Al cubrir al menos el 70% de los puntos clave, se valida como trazo exitoso
    final completionRatio = _hitCheckpoints.length / checkpoints.length;
    if (completionRatio >= 0.70 && !_isCompleted) {
      _triggerSuccess();
    }
  }

  void _triggerSuccess() {
    setState(() {
      _isCompleted = true;
    });

    // Retroalimentación de audio (TTS) con fonema y felicitación
    _ttsService.speak('¡Excelente! Has trazado la letra ${widget.letter.toUpperCase()}. ¡Mmm como en Mamá!');

    widget.onComplete?.call();
  }

  void _reset() {
    setState(() {
      _userPoints.clear();
      _hitCheckpoints.clear();
      _isCompleted = false;
    });
    _ttsService.speak('Vamos de nuevo. ¡Tú puedes trazar la letra ${widget.letter.toUpperCase()}!');
  }

  @override
  Widget build(BuildContext context) {
    final letterChar = widget.letter.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;

        // Dimensión responsiva libre de desbordamientos
        final maxCanvasHeight = (availableHeight - 130.0).clamp(220.0, 380.0);
        final maxCanvasWidth = (availableWidth - 24.0).clamp(220.0, 380.0);
        final canvasDimension = math.min(maxCanvasWidth, maxCanvasHeight);
        final canvasSize = Size(canvasDimension, canvasDimension);

        return SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado con instrucción amigable y escala contenida
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.deepOrangeAccent, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Traza la letra "${letterChar.toUpperCase()}"',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Área interactiva de trazado con RepaintBoundary para captura determinista
                RepaintBoundary(
                  key: const Key('tracing_repaint_boundary'),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lienzo de fondo con letra guía y trazo del niño
                      GestureDetector(
                        key: const Key('tracing_canvas_gesture'),
                        onPanStart: (d) => _onPanStart(d, canvasSize),
                        onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                        child: Container(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBE7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: _isCompleted ? Colors.amber : const Color(0xFF81C784),
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _LetterTracingPainter(
                              letter: letterChar,
                              userPoints: _userPoints,
                              checkpoints: normalizedCheckpointsM,
                              hitCheckpoints: _hitCheckpoints,
                              isCompleted: _isCompleted,
                            ),
                          ),
                        ),
                      ),

                      // Animación celebratoria sobrepuesta al completar
                      if (_isCompleted)
                        Positioned.fill(
                          child: Container(
                            key: const Key('celebration_overlay'),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(70),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Center(
                              child: CelebrationAnimation(
                                title: '¡Excelente!',
                                subtitle: 'Has trazado la letra "${letterChar.toUpperCase()}"',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Botón de reinicio táctil con objetivo táctil >= 48dp y contraste AA
                ElevatedButton.icon(
                  key: const Key('reset_button'),
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: const Text(
                    'Intentar de nuevo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), // Azul accesible 5.2:1 sobre blanco (WCAG AA)
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50), // Cumple estrictamente objetivo táctil >= 48dp
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Painter encargado de renderizar la letra guía, puntos de referencia y el trazo del párvulo.
class _LetterTracingPainter extends CustomPainter {
  final String letter;
  final List<Offset> userPoints;
  final List<Offset> checkpoints;
  final Set<int> hitCheckpoints;
  final bool isCompleted;

  _LetterTracingPainter({
    required this.letter,
    required this.userPoints,
    required this.checkpoints,
    required this.hitCheckpoints,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dibujar la letra guía con silueta semitransparente
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.height * 0.70,
          fontWeight: FontWeight.w900,
          color: Colors.grey.withAlpha(45),
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2 - (size.height * 0.04),
    );
    textPainter.paint(canvas, textOffset);

    // 2. Dibujar checkpoints guía interactivos
    final checkpointPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < checkpoints.length; i++) {
      final point = Offset(
        checkpoints[i].dx * size.width,
        checkpoints[i].dy * size.height,
      );

      final isHit = hitCheckpoints.contains(i);
      checkpointPaint.color = isHit
          ? Colors.greenAccent.shade700
          : Colors.orangeAccent.withAlpha(160);

      canvas.drawCircle(point, isHit ? 9.0 : 6.0, checkpointPaint);
    }

    // 3. Dibujar el trazo del niño con grosor táctil ergonómico
    if (userPoints.isNotEmpty) {
      final strokePaint = Paint()
        ..color = isCompleted ? Colors.amber.shade700 : const Color(0xFFE91E63)
        ..strokeWidth = 16.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(userPoints.first.dx, userPoints.first.dy);

      for (int i = 1; i < userPoints.length; i++) {
        path.lineTo(userPoints[i].dx, userPoints[i].dy);
      }

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LetterTracingPainter oldDelegate) => true;
}
