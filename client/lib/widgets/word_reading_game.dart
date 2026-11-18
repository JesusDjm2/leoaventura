import 'package:flutter/material.dart';
import '../content/activity_model.dart';
import '../services/haptic_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'animated_leo.dart';
import 'bouncy_button.dart';
import 'celebration_animation.dart';
import 'confetti_overlay.dart';
import 'reading_card.dart';
import 'word_illustration.dart';

/// 4.º Minijuego: "Lee tu primera palabra" (decodificación silábica + comprensión lectora).
///
/// Flujo pedagógico de 2 etapas para niños de 3 a 6 años:
/// 1. **Decodificación guiada:** El niño toca cada sílaba (`MA` -> `MÁ`) escuchándola
///    en voz alta hasta iluminar la palabra completa en [ReadingCard] (Andika).
/// 2. **Comprensión lectora:** El niño selecciona el dibujo que corresponde a la
///    palabra que acaba de leer, evitando adivinación mecánica.
class WordReadingGame extends StatefulWidget {
  final String targetWord;
  final List<String> syllables;
  final String highlightLetter;
  final String? audioKey;
  final List<WordReadingOption> options;
  final TtsService? ttsService;
  final HapticController? hapticController;
  final bool enableParticles;
  final VoidCallback? onComplete;

  const WordReadingGame({
    super.key,
    required this.targetWord,
    required this.syllables,
    this.highlightLetter = '',
    this.audioKey,
    required this.options,
    this.ttsService,
    this.hapticController,
    this.enableParticles = true,
    this.onComplete,
  });

  factory WordReadingGame.fromActivity(
    ActivityModel activity, {
    Key? key,
    TtsService? ttsService,
    HapticController? hapticController,
    bool enableParticles = true,
    VoidCallback? onComplete,
  }) {
    final payload = activity.wordReadingPayload;
    return WordReadingGame(
      key: key ?? Key('word_reading_${payload.targetWord.toLowerCase()}'),
      targetWord: payload.targetWord,
      syllables: payload.syllables,
      highlightLetter: payload.highlightLetter,
      audioKey: payload.audioKey.isNotEmpty ? payload.audioKey : activity.audioKey,
      options: payload.options,
      ttsService: ttsService,
      hapticController: hapticController,
      enableParticles: enableParticles,
      onComplete: onComplete,
    );
  }

  @override
  State<WordReadingGame> createState() => _WordReadingGameState();
}

class _WordReadingGameState extends State<WordReadingGame> {
  late final TtsService _ttsService;
  final Set<int> _tappedSyllables = <int>{};
  bool _wordDecoded = false;
  bool _isSuccess = false;
  String? _selectedWord;
  String _leoState = AnimatedLeoStateName.idle;

  HapticController get _haptics => widget.hapticController ?? HapticService.instance;

  List<String> get _syllables =>
      widget.syllables.isNotEmpty ? widget.syllables : [widget.targetWord.toUpperCase()];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService.shared;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ttsService.speak(
        'Toca cada sílaba para leer la palabra y luego elige su dibujo.',
      );
    });
  }

  void _onSyllableTapped(int index) {
    final syllable = _syllables[index];
    _haptics.lightImpact();

    final wasDecoded = _wordDecoded;
    setState(() {
      _tappedSyllables.add(index);
      if (_tappedSyllables.length >= _syllables.length) {
        _wordDecoded = true;
      }
      if (_leoState == AnimatedLeoStateName.sad) {
        _leoState = AnimatedLeoStateName.idle;
      }
    });

    if (_wordDecoded && !wasDecoded) {
      _ttsService.speak('$syllable. ¡Muy bien! Dice ${widget.targetWord}. Ahora toca el dibujo de ${widget.targetWord}.');
    } else {
      _ttsService.speak(syllable);
    }
  }

  void _speakFullWord() {
    _haptics.lightImpact();
    _ttsService.playClip(
      widget.audioKey,
      fallbackText: widget.targetWord,
    );
  }

  void _onOptionTapped(WordReadingOption option) {
    if (_isSuccess) return;

    setState(() {
      _selectedWord = option.word;
    });

    if (option.isCorrect) {
      _haptics.mediumImpact();
      _ttsService.speak('¡Bravo! Leíste ${widget.targetWord}.');
      setState(() {
        _wordDecoded = true;
        _tappedSyllables.addAll(List.generate(_syllables.length, (i) => i));
        _isSuccess = true;
        _leoState = AnimatedLeoStateName.happy;
      });
      widget.onComplete?.call();
    } else {
      _ttsService.speak('Ese dibujo es ${option.word}. Busca ${widget.targetWord}.');
      setState(() {
        _leoState = AnimatedLeoStateName.sad;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Mascota guía Leo + instrucción contextual
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedLeo(
                      key: const Key('word_reading_leo'),
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
                          _isSuccess
                              ? '¡Excelente! Leíste "${widget.targetWord}"'
                              : _wordDecoded
                                  ? '¡Dice ${widget.targetWord}! Toca su dibujo:'
                                  : 'Toca cada sílaba para leer la palabra:',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Fichas de sílabas interactivas
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(_syllables.length, (index) {
                    final syllable = _syllables[index];
                    final isTapped = _tappedSyllables.contains(index);

                    return AnimatedSlide(
                      offset: isTapped ? const Offset(0, -0.08) : Offset.zero,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: AnimatedScale(
                        scale: isTapped ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: BouncyButton(
                          pressedScale: 0.94,
                          child: Semantics(
                            label: 'Sílaba $syllable',
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: Key('word_syllable_$index'),
                                onTap: () => _onSyllableTapped(index),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  constraints: const BoxConstraints(minWidth: 68, minHeight: 58),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isTapped ? AppColors.brandOrange : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isTapped ? AppColors.navy : AppColors.brandCyan,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isTapped
                                            ? AppColors.brandOrange.withValues(alpha: 0.35)
                                            : AppColors.navy.withValues(alpha: 0.12),
                                        blurRadius: isTapped ? 14 : 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      syllable,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.navy,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // 3. Tarjeta de Lectura Andika (ReadingCard) con la palabra completa
                ReadingCard(
                  key: const Key('word_reading_card'),
                  text: widget.targetWord,
                  highlightedPart: widget.highlightLetter.isNotEmpty
                      ? widget.highlightLetter
                      : null,
                  subtitle: _syllables.join(' · '),
                  height: 132,
                  onTap: _speakFullWord,
                  onAudioTap: _speakFullWord,
                ),

                const SizedBox(height: 20),

                // 4. Comprensión lectora: elige el dibujo que corresponde a la palabra leída
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _wordDecoded ? 1.0 : 0.72,
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: widget.options.map((option) {
                      final isSelected = _selectedWord == option.word;
                      final showGreen = isSelected && option.isCorrect;

                      return BouncyButton(
                        pressedScale: 0.94,
                        child: Semantics(
                          label: 'Dibujo ${option.word}',
                          button: true,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: Key('word_option_${option.word}'),
                              onTap: () => _onOptionTapped(option),
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 108,
                                constraints: const BoxConstraints(minHeight: 112),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: showGreen
                                      ? AppColors.brandGreen.withValues(alpha: 0.45)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: showGreen
                                        ? AppColors.secondary
                                        : isSelected
                                            ? AppColors.brandOrange
                                            : AppColors.brandCyan,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withValues(alpha: 0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WordIllustration(
                                      imageKey: option.imageKey,
                                      emoji: option.emoji,
                                      label: option.word,
                                      size: 64,
                                      highlighted: showGreen,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isSuccess && option.isCorrect ? option.word : '?',
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: showGreen ? AppColors.secondary : AppColors.textMuted,
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
                ),

                if (_isSuccess) ...[
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CelebrationAnimation(
                      title: '¡Ya sabes leer!',
                      subtitle: 'Leíste "${widget.targetWord}"',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.enableParticles)
          ConfettiOverlay(
            key: const Key('word_reading_confetti'),
            active: _isSuccess,
            effectName: 'bubbles',
          ),
      ],
    );
  }
}
