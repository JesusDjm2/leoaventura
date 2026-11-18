import 'package:flutter/material.dart';
import '../content/activity_model.dart';
import '../services/bundled_clip_player.dart';
import '../services/haptic_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'animated_leo.dart';
import 'bouncy_button.dart';
import 'celebration_animation.dart';
import 'confetti_overlay.dart';

/// Minijuego 3: Constructor de Sílabas Mágicas.
/// Permite al párvulo combinar consonante + vocal (ej: M + A = MA, S + O = SO)
/// con disparo fonético inmediato, feedback háptico, partículas y refuerzo visual.
class SyllableBuilderGame extends StatefulWidget {
  final String consonant;
  final String? exampleWord;
  final List<String> vowels;
  final TtsService? ttsService;
  final HapticController? hapticController;
  final bool enableParticles;
  final VoidCallback? onComplete;

  const SyllableBuilderGame({
    super.key,
    this.consonant = 'M',
    this.exampleWord,
    this.vowels = const ['A', 'E', 'I', 'O', 'U'],
    this.ttsService,
    this.hapticController,
    this.enableParticles = true,
    this.onComplete,
  });

  /// Construye el minijuego dinámicamente desde un [ActivityModel] (`type == 'syllable_builder'`).
  factory SyllableBuilderGame.fromActivity(
    ActivityModel activity, {
    Key? key,
    TtsService? ttsService,
    HapticController? hapticController,
    bool enableParticles = true,
    VoidCallback? onComplete,
  }) {
    final payload = activity.syllableBuilderPayload;
    return SyllableBuilderGame(
      key: key,
      consonant: payload.consonant,
      exampleWord: payload.exampleWord.isNotEmpty ? payload.exampleWord : null,
      vowels: payload.vowels,
      ttsService: ttsService,
      hapticController: hapticController,
      enableParticles: enableParticles,
      onComplete: onComplete,
    );
  }

  @override
  State<SyllableBuilderGame> createState() => _SyllableBuilderGameState();
}

class _SyllableBuilderGameState extends State<SyllableBuilderGame> {
  late final TtsService _ttsService;
  String? _selectedVowel;
  bool _isSuccess = false;
  String _leoState = 'idle';

  HapticController get _haptics => widget.hapticController ?? HapticService.instance;

  String get _consonantUpper => widget.consonant.toUpperCase();

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService.shared;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ttsService.playClip(
        'instrucciones/instruccion_silaba_junta',
        fallbackText: 'Junta la letra $_consonantUpper con una vocal.',
      );
    });
  }

  @override
  void dispose() {
    _ttsService.stopPlayback();
    super.dispose();
  }

  void _onVowelTapped(String vowel) {
    final syllable = '$_consonantUpper$vowel';
    final wordHint = (widget.exampleWord != null && widget.exampleWord!.isNotEmpty)
        ? ' ¡$syllable como en ${widget.exampleWord}!'
        : ' ¡Muy bien!';

    // Disparo fonético inmediato (< 100 ms): usa tu grabación de la sílaba si existe
    _ttsService.playClip(
      'silabas/silaba_${normalizeAudioSlug(syllable)}',
      fallbackText: '¡La $_consonantUpper con la $vowel suena $syllable!$wordHint',
    );

    setState(() {
      _selectedVowel = vowel;
      _isSuccess = true;
      _leoState = 'happy';
    });

    _haptics.mediumImpact();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentSyllable = _selectedVowel != null ? '$_consonantUpper$_selectedVowel' : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Guía empática de Leo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedLeo(
                      key: const Key('syllable_builder_leo'),
                      state: _leoState,
                      size: 64,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.brandCyan, width: 2),
                        ),
                        child: Text(
                          currentSyllable != null
                              ? '¡Genial! Formaste la sílaba $currentSyllable'
                              : 'Toca una vocal para juntarla con $_consonantUpper',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Visualizador de la sílaba en formación
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _isSuccess ? AppColors.secondary : AppColors.brandCyan,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Consonante fija
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _consonantUpper,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Vocal seleccionada
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _selectedVowel != null
                                ? AppColors.primary
                                : AppColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _selectedVowel ?? '?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _selectedVowel != null
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '=',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Resultado con fusión magnética elástica (M + A -> MA)
                        TweenAnimationBuilder<double>(
                          key: ValueKey(currentSyllable ?? 'pending'),
                          tween: Tween(begin: currentSyllable != null ? 0.55 : 1.0, end: 1.0),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          builder: (_, scale, child) => Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: _isSuccess
                                ? BoxDecoration(
                                    color: AppColors.brandGreen.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(16),
                                  )
                                : null,
                            child: Text(
                              currentSyllable ?? '...',
                              key: const Key('syllable_result_text'),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: _isSuccess ? AppColors.secondary : AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botones táctiles de las 5 vocales
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: widget.vowels.map((v) {
                    final isSelected = _selectedVowel == v;
                    return BouncyButton(
                      pressedScale: 0.94,
                      child: Semantics(
                        label: 'Vocal $v',
                        button: true,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: Key('vowel_btn_$v'),
                            onTap: () => _onVowelTapped(v),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brandOrange : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.navy : AppColors.primary,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.navy.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  v,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppColors.navy : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_isSuccess && currentSyllable != null) ...[
                  const SizedBox(height: 18),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CelebrationAnimation(
                      title: '¡Sílaba Mágica!',
                      subtitle: '¡Has formado $currentSyllable!',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.enableParticles)
          ConfettiOverlay(
            key: const Key('syllable_builder_confetti'),
            active: _isSuccess,
            effectName: 'star_burst',
          ),
      ],
    );
  }
}
