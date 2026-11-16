import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import 'celebration_animation.dart';

/// Minijuego 3: Constructor de Sílabas Mágicas.
/// Permite al párvulo combinar consonante + vocal (ej: M + A = MA)
/// con disparo fonético inmediato y refuerzo visual.
class SyllableBuilderGame extends StatefulWidget {
  final String consonant;
  final TtsService? ttsService;
  final VoidCallback? onComplete;

  const SyllableBuilderGame({
    super.key,
    this.consonant = 'M',
    this.ttsService,
    this.onComplete,
  });

  @override
  State<SyllableBuilderGame> createState() => _SyllableBuilderGameState();
}

class _SyllableBuilderGameState extends State<SyllableBuilderGame> {
  late final TtsService _ttsService;
  String? _selectedVowel;
  bool _isSuccess = false;

  final List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttsService.speak('Junta la letra ${widget.consonant} con una vocal.');
    });
  }

  void _onVowelTapped(String vowel) {
    setState(() {
      _selectedVowel = vowel;
      _isSuccess = true;
    });

    final syllable = '${widget.consonant}$vowel';
    // Disparo inmediato de la sílaba construida
    _ttsService.speak('¡La ${widget.consonant} con la $vowel suena $syllable! ¡$syllable como en Mamá!');
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visualizador de la sílaba en formación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFCFD8DC),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Consonante fija
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00695C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.consonant,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2933))),
                const SizedBox(width: 12),
                // Vocal seleccionada
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedVowel != null ? const Color(0xFFBF360C) : const Color(0xFFECEFF1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _selectedVowel ?? '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _selectedVowel != null ? Colors.white : const Color(0xFF78909C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('=', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2933))),
                const SizedBox(width: 16),
                // Resultado
                Text(
                  _selectedVowel != null ? '${widget.consonant}$_selectedVowel' : '...',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFF37474F),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Botones táctiles de las 5 vocales
          Stack(
            alignment: Alignment.center,
            children: [
              Wrap(
                spacing: 12,
                children: _vowels.map((v) {
                  return Semantics(
                    label: 'Vocal $v',
                    button: true,
                    child: InkWell(
                      key: Key('vowel_btn_$v'),
                      onTap: () => _onVowelTapped(v),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBF360C), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            v,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFBF360C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_isSuccess)
                const Positioned.fill(
                  child: Center(
                    child: CelebrationAnimation(
                      title: '¡Sílaba Mágica!',
                      subtitle: '¡Has formado MA!',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
