import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../content/activity_model.dart';
import '../services/haptic_service.dart';
import '../services/tts_service.dart';
import 'animated_leo.dart';
import 'celebration_animation.dart';
import 'confetti_overlay.dart';

/// Widget de trazado táctil dinámico para párvulos.
/// Recibe por parámetros la letra, clave de audio, fonema, palabra de ejemplo,
/// textos de locución y puntos guía normalizados (0.0 a 1.0), permitiendo renderizar
/// cualquier fonema servido por el Motor de Contenido Dinámico (Fase 16).
class LetterTracing extends StatefulWidget {
  final String letter;
  final String? audioKey;
  final String? phoneme;
  final String? exampleWord;
  final String? instructionText;
  final String? successText;
  final List<Offset>? checkpoints;
  final VoidCallback? onComplete;
  final TtsService? ttsService;

  const LetterTracing({
    super.key,
    required this.letter,
    this.audioKey,
    this.phoneme,
    this.exampleWord,
    this.instructionText,
    this.successText,
    this.checkpoints,
    this.onComplete,
    this.ttsService,
  });

  /// Construye el minijuego directamente desde un [ActivityModel] del backend.
  factory LetterTracing.fromActivity(
    ActivityModel activity, {
    Key? key,
    VoidCallback? onComplete,
    TtsService? ttsService,
  }) {
    final payload = activity.tracingPayload;
    return LetterTracing(
      key: key ?? Key('letter_tracing_${payload.letter.toLowerCase()}'),
      letter: payload.letter,
      audioKey: payload.audioKey.isNotEmpty ? payload.audioKey : activity.audioKey,
      phoneme: payload.phoneme,
      exampleWord: payload.exampleWord,
      instructionText: activity.instruction.isNotEmpty ? activity.instruction : null,
      successText: payload.successText,
      checkpoints: payload.checkpoints.isNotEmpty ? payload.checkpoints : null,
      onComplete: onComplete,
      ttsService: ttsService,
    );
  }

  /// Checkpoints pedagógicos normalizados (0.0 a 1.0) para los 20 fonemas del currículo.
  /// Siguen direccionalidad de escritura escolar: arriba -> abajo, izquierda -> derecha.
  static const Map<String, List<Offset>> defaultCheckpointsByLetter = {
    'a': [
      Offset(0.50, 0.25),
      Offset(0.38, 0.50),
      Offset(0.28, 0.75),
      Offset(0.62, 0.50),
      Offset(0.72, 0.75),
      Offset(0.50, 0.58),
    ],
    'e': [
      Offset(0.36, 0.50),
      Offset(0.64, 0.50),
      Offset(0.56, 0.34),
      Offset(0.36, 0.38),
      Offset(0.36, 0.64),
      Offset(0.58, 0.72),
    ],
    'i': [
      Offset(0.50, 0.26),
      Offset(0.50, 0.44),
      Offset(0.50, 0.60),
      Offset(0.50, 0.75),
    ],
    'o': [
      Offset(0.50, 0.28),
      Offset(0.32, 0.50),
      Offset(0.50, 0.72),
      Offset(0.68, 0.50),
    ],
    'u': [
      Offset(0.32, 0.35),
      Offset(0.34, 0.62),
      Offset(0.50, 0.74),
      Offset(0.66, 0.62),
      Offset(0.68, 0.35),
    ],
    'm': [
      Offset(0.22, 0.35),
      Offset(0.22, 0.55),
      Offset(0.22, 0.75),
      Offset(0.36, 0.35),
      Offset(0.50, 0.55),
      Offset(0.50, 0.75),
      Offset(0.64, 0.35),
      Offset(0.78, 0.55),
      Offset(0.78, 0.75),
    ],
    'p': [
      Offset(0.35, 0.30),
      Offset(0.35, 0.55),
      Offset(0.35, 0.78),
      Offset(0.55, 0.30),
      Offset(0.65, 0.42),
      Offset(0.52, 0.54),
    ],
    's': [
      Offset(0.64, 0.30),
      Offset(0.48, 0.26),
      Offset(0.34, 0.38),
      Offset(0.50, 0.50),
      Offset(0.66, 0.62),
      Offset(0.50, 0.74),
      Offset(0.34, 0.70),
    ],
    'l': [
      Offset(0.40, 0.25),
      Offset(0.40, 0.50),
      Offset(0.40, 0.75),
      Offset(0.62, 0.75),
    ],
    't': [
      Offset(0.50, 0.25),
      Offset(0.50, 0.50),
      Offset(0.50, 0.75),
      Offset(0.34, 0.40),
      Offset(0.66, 0.40),
    ],
    'n': [
      Offset(0.32, 0.35),
      Offset(0.32, 0.75),
      Offset(0.50, 0.35),
      Offset(0.68, 0.55),
      Offset(0.68, 0.75),
    ],
    'd': [
      Offset(0.64, 0.24),
      Offset(0.64, 0.50),
      Offset(0.64, 0.75),
      Offset(0.48, 0.46),
      Offset(0.34, 0.58),
      Offset(0.50, 0.72),
    ],
    'f': [
      Offset(0.62, 0.26),
      Offset(0.48, 0.30),
      Offset(0.46, 0.52),
      Offset(0.46, 0.75),
      Offset(0.34, 0.48),
      Offset(0.60, 0.48),
    ],
    'r': [
      Offset(0.38, 0.34),
      Offset(0.38, 0.55),
      Offset(0.38, 0.75),
      Offset(0.50, 0.36),
      Offset(0.64, 0.36),
    ],
    'b': [
      Offset(0.36, 0.24),
      Offset(0.36, 0.50),
      Offset(0.36, 0.75),
      Offset(0.54, 0.48),
      Offset(0.64, 0.60),
      Offset(0.50, 0.74),
    ],
    'c': [
      Offset(0.66, 0.34),
      Offset(0.48, 0.28),
      Offset(0.34, 0.50),
      Offset(0.48, 0.72),
      Offset(0.66, 0.66),
    ],
    'g': [
      Offset(0.62, 0.34),
      Offset(0.42, 0.34),
      Offset(0.34, 0.50),
      Offset(0.56, 0.58),
      Offset(0.62, 0.70),
      Offset(0.42, 0.80),
    ],
    'j': [
      Offset(0.54, 0.24),
      Offset(0.54, 0.44),
      Offset(0.54, 0.66),
      Offset(0.46, 0.78),
      Offset(0.36, 0.74),
    ],
    'v': [
      Offset(0.30, 0.32),
      Offset(0.40, 0.54),
      Offset(0.50, 0.74),
      Offset(0.60, 0.54),
      Offset(0.70, 0.32),
    ],
    'ñ': [
      Offset(0.32, 0.40),
      Offset(0.32, 0.75),
      Offset(0.50, 0.42),
      Offset(0.68, 0.58),
      Offset(0.68, 0.75),
      Offset(0.36, 0.26),
      Offset(0.64, 0.26),
    ],
  };

  static const List<Offset> fallbackCheckpoints = [
    Offset(0.35, 0.30),
    Offset(0.50, 0.40),
    Offset(0.50, 0.55),
    Offset(0.50, 0.70),
    Offset(0.65, 0.75),
  ];

  /// Resuelve los checkpoints efectivos para esta instancia.
  List<Offset> get resolvedCheckpoints {
    if (checkpoints != null && checkpoints!.isNotEmpty) {
      return checkpoints!;
    }
    return defaultCheckpointsByLetter[letter.toLowerCase()] ?? fallbackCheckpoints;
  }

  @override
  State<LetterTracing> createState() => _LetterTracingState();
}

class _LetterTracingState extends State<LetterTracing>
    with SingleTickerProviderStateMixin {
  late final TtsService _ttsService;
  late final AnimationController _guideController;

  final List<Offset> _userPoints = [];
  final Set<int> _hitCheckpoints = {};
  bool _isCompleted = false;
  String _leoState = AnimatedLeoStateName.idle;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  String get _upperLetter => widget.letter.toUpperCase();
  String get _lowerLetter => widget.letter.toLowerCase();

  String get _resolvedInstruction =>
      widget.instructionText ??
      '¡Hola! Traza la letra $_upperLetter con tu dedito.';

  String get _resolvedSuccessAudio {
    if (widget.successText != null && widget.successText!.isNotEmpty) {
      return widget.successText!;
    }
    if (widget.exampleWord != null && widget.exampleWord!.isNotEmpty) {
      final cue = widget.phoneme ?? _upperLetter;
      return '¡Excelente! Has trazado la letra $_upperLetter. ¡$cue como en ${widget.exampleWord}!';
    }
    if (_lowerLetter == 'm') {
      return '¡Excelente! Has trazado la letra M. ¡Mmm como en Mamá!';
    }
    return '¡Excelente! Has trazado la letra $_upperLetter.';
  }

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService.shared;
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (!_isWidgetTest) {
      _guideController.repeat();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _guideController.stop();
      }
      _ttsService.playClip(
        widget.audioKey,
        fallbackText: _resolvedInstruction,
      );
    });
  }

  @override
  void dispose() {
    _ttsService.stopPlayback();
    _guideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LetterTracing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter ||
        oldWidget.audioKey != widget.audioKey) {
      _userPoints.clear();
      _hitCheckpoints.clear();
      _isCompleted = false;
    }
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    if (_isCompleted) return;
    if (_leoState != AnimatedLeoStateName.idle) {
      setState(() => _leoState = AnimatedLeoStateName.idle);
    }
    _addPoint(details.localPosition, canvasSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_isCompleted) return;
    _addPoint(details.localPosition, canvasSize);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted || _userPoints.isEmpty) return;
    // Si soltó el trazo sin completar la letra, Leo responde de forma empática (nunca punitiva)
    setState(() {
      _leoState = AnimatedLeoStateName.sad;
    });
  }

  void _addPoint(Offset localPosition, Size canvasSize) {
    setState(() {
      _userPoints.add(localPosition);
    });

    _checkHitpoints(localPosition, canvasSize);
  }

  void _checkHitpoints(Offset point, Size canvasSize) {
    final checkpoints = widget.resolvedCheckpoints;
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
      _leoState = AnimatedLeoStateName.happy;
    });

    HapticService.mediumImpact();
    _ttsService.playClip(
      widget.audioKey,
      fallbackText: _resolvedSuccessAudio,
    );

    widget.onComplete?.call();
  }

  void _reset() {
    setState(() {
      _userPoints.clear();
      _hitCheckpoints.clear();
      _isCompleted = false;
      _leoState = AnimatedLeoStateName.idle;
    });
    _ttsService.playClip(
      'instrucciones/instruccion_reintentar',
      fallbackText: 'Vamos de nuevo. ¡Tú puedes trazar la letra $_upperLetter!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final letterChar = _lowerLetter;
    final checkpoints = widget.resolvedCheckpoints;

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
                // Encabezado con mascota animada Rive (<AnimatedLeo />) e instrucción amigable
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedLeo(
                        key: const Key('tracing_animated_leo'),
                        state: _leoState,
                        size: 56,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
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
                              'Traza la letra "$_upperLetter"',
                              key: const Key('tracing_header_text'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF263238),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Semantics(
                              label: 'Escuchar sonido de la letra $_upperLetter',
                              button: true,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  key: const Key('tracing_play_sound_btn'),
                                  tooltip: 'Escuchar fonema',
                                  icon: const Icon(
                                    Icons.volume_up_rounded,
                                    color: Color(0xFF1565C0),
                                    size: 26,
                                  ),
                                  onPressed: () {
                                    HapticService.lightImpact();
                                    _ttsService.playClip(
                                      widget.audioKey,
                                      fallbackText: _resolvedInstruction,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      Semantics(
                        label: 'Área de trazado para la letra $letterChar',
                        child: GestureDetector(
                          key: const Key('tracing_canvas_gesture'),
                          onPanStart: (d) => _onPanStart(d, canvasSize),
                          onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                          onPanEnd: _onPanEnd,
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
                            child: AnimatedBuilder(
                              animation: _guideController,
                              builder: (_, __) => CustomPaint(
                                key: Key('tracing_guide_canvas_$letterChar'),
                                size: canvasSize,
                                painter: LetterTracingPainter(
                                  letter: letterChar,
                                  userPoints: _userPoints,
                                  checkpoints: checkpoints,
                                  hitCheckpoints: _hitCheckpoints,
                                  isCompleted: _isCompleted,
                                  guideProgress: _guideController.value,
                                  showGuideStar: _userPoints.isEmpty && !_isCompleted,
                                ),
                              ),
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
                                subtitle: 'Has trazado la letra "$_upperLetter"',
                              ),
                            ),
                          ),
                        ),

                      // Partículas de confeti impulsadas por Flame al ganar
                      ConfettiOverlay(
                        key: const Key('tracing_confetti_overlay'),
                        active: _isCompleted,
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

/// Painter encargado de renderizar la letra guía, estrellita guía animada,
/// puntos de referencia con halo, trazo del párvulo y rastro mágico de chispas.
class LetterTracingPainter extends CustomPainter {
  final String letter;
  final List<Offset> userPoints;
  final List<Offset> checkpoints;
  final Set<int> hitCheckpoints;
  final bool isCompleted;
  final double guideProgress;
  final bool showGuideStar;

  LetterTracingPainter({
    required this.letter,
    required this.userPoints,
    required this.checkpoints,
    required this.hitCheckpoints,
    required this.isCompleted,
    this.guideProgress = 0.0,
    this.showGuideStar = false,
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

    // 2. Dibujar puntos de guía interactivos sobre la trayectoria de la letra
    for (int i = 0; i < checkpoints.length; i++) {
      final pt = Offset(
        checkpoints[i].dx * size.width,
        checkpoints[i].dy * size.height,
      );
      final isHit = hitCheckpoints.contains(i);

      if (isHit) {
        final haloPaint = Paint()
          ..color = const Color(0xFF66BB6A).withAlpha(80)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 16, haloPaint);
      }

      final dotPaint = Paint()
        ..color = isHit ? const Color(0xFF4CAF50) : Colors.deepOrangeAccent.withAlpha(115)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, isHit ? 10 : 8, dotPaint);
    }

    // 2.5 Estrellita dorada guía recorriendo la letra antes de que el niño trace
    if (showGuideStar && checkpoints.length >= 2) {
      final scaled = guideProgress.clamp(0.0, 0.999) * (checkpoints.length - 1);
      final segIndex = scaled.floor().clamp(0, checkpoints.length - 2);
      final segT = scaled - segIndex;
      final a = Offset(
        checkpoints[segIndex].dx * size.width,
        checkpoints[segIndex].dy * size.height,
      );
      final b = Offset(
        checkpoints[segIndex + 1].dx * size.width,
        checkpoints[segIndex + 1].dy * size.height,
      );
      final guidePos = Offset.lerp(a, b, segT)!;

      canvas.drawCircle(
        guidePos,
        18,
        Paint()..color = const Color(0xFFFFCA28).withAlpha(75),
      );
      _drawStar(canvas, guidePos, 11, const Color(0xFFFFA000));
    }

    // 3. Dibujar el trazo continuo del niño con pincel grueso + chispas mágicas
    if (userPoints.length > 1) {
      final strokePaint = Paint()
        ..color = isCompleted ? const Color(0xFFFFA000) : const Color(0xFF29B6F6)
        ..strokeWidth = 22.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(userPoints.first.dx, userPoints.first.dy);
      for (int i = 1; i < userPoints.length; i++) {
        path.lineTo(userPoints[i].dx, userPoints[i].dy);
      }
      canvas.drawPath(path, strokePaint);

      // Chispas mágicas sutiles sobre los últimos puntos del trazo
      const sparkleColors = [
        Color(0xFFFFD54F),
        Color(0xFFFF9E3D),
        Color(0xFF62C462),
        Color(0xFF5BC0EB),
      ];
      final startIdx = math.max(0, userPoints.length - 14);
      for (int i = startIdx; i < userPoints.length; i += 3) {
        final ageFactor = (i - startIdx + 1) / (userPoints.length - startIdx + 1);
        final angle = i * 1.3;
        final sparkleOffset = userPoints[i] +
            Offset(math.cos(angle) * 14, math.sin(angle) * 14);
        _drawStar(
          canvas,
          sparkleOffset,
          4.5 + ageFactor * 3.5,
          sparkleColors[i % sparkleColors.length].withValues(alpha: ageFactor),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const spikes = 5;
    final inner = radius * 0.48;
    for (int i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = -math.pi / 2 + (i * math.pi / spikes);
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant LetterTracingPainter oldDelegate) => true;
}
