import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../content/activity_model.dart';
import '../services/haptic_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'animated_leo.dart';
import 'bouncy_button.dart';
import 'celebration_animation.dart';
import 'confetti_overlay.dart';
import 'word_illustration.dart';

/// Minijuego 2: Discriminación Auditiva de Fonemas (dinámico desde Fase 16).
/// El niño escucha el fonema y selecciona el objeto que comienza con dicho sonido.
class SoundMatchGame extends StatefulWidget {
  final String targetLetter;
  final String targetPhoneme;
  final String? audioKey;
  final String? instructionText;
  final List<SoundMatchOption>? options;
  final TtsService? ttsService;
  final VoidCallback? onComplete;

  const SoundMatchGame({
    super.key,
    this.targetLetter = 'P',
    this.targetPhoneme = '/p/ /p/',
    this.audioKey,
    this.instructionText,
    this.options,
    this.ttsService,
    this.onComplete,
  });

  /// Construye el minijuego dinámicamente a partir de un [ActivityModel].
  factory SoundMatchGame.fromActivity(
    ActivityModel activity, {
    Key? key,
    TtsService? ttsService,
    VoidCallback? onComplete,
  }) {
    final payload = activity.soundMatchPayload;
    return SoundMatchGame(
      key: key ?? Key('sound_match_${payload.targetLetter.toLowerCase()}'),
      targetLetter: payload.targetLetter,
      targetPhoneme: payload.targetPhoneme,
      audioKey: payload.audioKey.isNotEmpty ? payload.audioKey : activity.audioKey,
      instructionText: activity.instruction.isNotEmpty ? activity.instruction : null,
      options: payload.options.isNotEmpty ? payload.options : null,
      ttsService: ttsService,
      onComplete: onComplete,
    );
  }

  @override
  State<SoundMatchGame> createState() => _SoundMatchGameState();
}

class _SoundMatchGameState extends State<SoundMatchGame>
    with TickerProviderStateMixin {
  late final TtsService _ttsService;
  late final AnimationController _waveController;
  late final AnimationController _wiggleController;
  bool _isSuccess = false;
  String? _selectedItem;
  String? _wigglingItem;
  int _missCount = 0;
  String _leoState = AnimatedLeoStateName.idle;

  static const List<SoundMatchOption> _defaultOptions = [
    SoundMatchOption(
      name: 'Pato',
      imageKey: 'palabras/p_pato',
      emoji: '🦆',
      isCorrect: true,
      feedbackText: '¡Pato! Empieza con /p/.',
      audioKey: 'palabras/pato',
    ),
    SoundMatchOption(
      name: 'Sol',
      imageKey: 'palabras/s_sol',
      emoji: '🌞',
      isCorrect: false,
      feedbackText: 'Sol empieza con /s/.',
      audioKey: 'palabras/sol',
    ),
    SoundMatchOption(
      name: 'Manzana',
      imageKey: 'palabras/m_manzana',
      emoji: '🍎',
      isCorrect: false,
      feedbackText: 'Manzana empieza con /m/.',
      audioKey: 'palabras/manzana',
    ),
  ];

  List<SoundMatchOption> get _effectiveOptions =>
      (widget.options != null && widget.options!.isNotEmpty)
          ? widget.options!
          : _defaultOptions;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService.shared;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playTargetPhoneme();
    });
  }

  @override
  void dispose() {
    _ttsService.stopPlayback();
    _waveController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _playTargetPhoneme() {
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _waveController.forward(from: 0.0);
    }
    final instruction = widget.instructionText ??
        'Toca el dibujo que empieza con ${widget.targetPhoneme}.';
    _ttsService.playClip(
      widget.audioKey,
      fallbackText: instruction,
    );
  }

  void _onItemTapped(SoundMatchOption item) {
    if (_isSuccess) return;

    setState(() {
      _selectedItem = item.name;
    });

    if (item.isCorrect) {
      // Disparo inmediato de audio fonético + vibración de éxito + estado Rive Happy
      HapticService.mediumImpact();
      _ttsService.playClip(
        item.audioKey.isNotEmpty ? item.audioKey : 'mascota/mascota_exi_bien_hecho',
        fallbackText: '¡Excelente! ${item.feedbackText}',
      );
      setState(() {
        _isSuccess = true;
        _wigglingItem = null;
        _leoState = AnimatedLeoStateName.happy;
      });
      widget.onComplete?.call();
    } else {
      // Feedback empático no punitivo + wiggle cariñoso + pista tras 2 fallos
      _ttsService.playClip(
        'mascota/mascota_err_cerca',
        fallbackText: '¡Casi! ${item.feedbackText} Prueba con otro.',
      );
      setState(() {
        _missCount++;
        _wigglingItem = item.name;
        _leoState = AnimatedLeoStateName.sad;
      });
      if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
        _wiggleController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedLeo(
              key: const Key('sound_match_animated_leo'),
              state: _leoState,
              size: 86,
              showMoodBadge: true,
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final t = _waveController.value;
                final waveAlpha = (1.0 - t).clamp(0.0, 1.0) * 0.45;
                final spread = _waveController.isAnimating ? 4.0 + t * 14.0 : 0.0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: _waveController.isAnimating
                        ? [
                            BoxShadow(
                              color: AppColors.brandCyan.withValues(alpha: waveAlpha),
                              blurRadius: 12 + t * 10,
                              spreadRadius: spread,
                            ),
                          ]
                        : const [],
                  ),
                  child: child,
                );
              },
              child: BouncyButton(
                pressedScale: 0.95,
                child: Semantics(
                  label: 'Escuchar el fonema ${widget.targetLetter}',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('sound_match_play_btn'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: _playTargetPhoneme,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.brandCyan, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.volume_up_rounded, color: Color(0xFF1565C0), size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'Busca el fonema ${widget.targetLetter} (${widget.targetPhoneme})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2933)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Opciones de discriminación auditiva
          Stack(
            alignment: Alignment.center,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _effectiveOptions.map((item) {
                  final isSelected = _selectedItem == item.name;
                  final isCorrect = item.isCorrect;
                  final isWiggling = _wigglingItem == item.name;
                  final showGentleHint = !_isSuccess && _missCount >= 2 && isCorrect;

                  return AnimatedBuilder(
                    animation: _wiggleController,
                    builder: (context, child) {
                      final dx = isWiggling && _wiggleController.isAnimating
                          ? math.sin(_wiggleController.value * math.pi * 3) * 7.0
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: BouncyButton(
                      pressedScale: 0.95,
                      child: Semantics(
                        label: 'Opción ${item.name}',
                        button: true,
                        child: InkWell(
                          key: Key('match_item_${item.name}'),
                          onTap: () => _onItemTapped(item),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 108,
                            constraints: const BoxConstraints(minHeight: 116),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected && isCorrect
                                  ? const Color(0xFFC8E6C9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected && isCorrect
                                    ? const Color(0xFF2E7D32)
                                    : showGentleHint
                                        ? AppColors.brandOrange
                                        : const Color(0xFFCFD8DC),
                                width: (isSelected || showGentleHint) ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: showGentleHint
                                      ? AppColors.brandOrange.withValues(alpha: 0.35)
                                      : Colors.black.withAlpha(20),
                                  blurRadius: showGentleHint ? 16 : 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              WordIllustration(
                                imageKey: item.imageKey,
                                emoji: item.emoji,
                                label: item.name,
                                size: 60,
                                highlighted: isSelected && isCorrect,
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2933)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  );
                }).toList(),
              ),

              if (_isSuccess)
                Positioned.fill(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CelebrationAnimation(
                        title: '¡Muy Bien!',
                        subtitle: '¡${_selectedItem ?? ''} empieza con ${widget.targetLetter}!',
                      ),
                    ),
                  ),
                ),

              ConfettiOverlay(
                key: const Key('sound_match_confetti_overlay'),
                active: _isSuccess,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
