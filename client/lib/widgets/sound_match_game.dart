import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import 'celebration_animation.dart';

/// Minijuego 2: Discriminación Auditiva de Fonemas (Ej: Letra P).
/// El niño escucha el fonema y selecciona el objeto que comienza con dicho sonido.
class SoundMatchGame extends StatefulWidget {
  final String targetLetter;
  final String targetPhoneme;
  final TtsService? ttsService;
  final VoidCallback? onComplete;

  const SoundMatchGame({
    super.key,
    this.targetLetter = 'P',
    this.targetPhoneme = '/p/ /p/',
    this.ttsService,
    this.onComplete,
  });

  @override
  State<SoundMatchGame> createState() => _SoundMatchGameState();
}

class _SoundMatchGameState extends State<SoundMatchGame> {
  late final TtsService _ttsService;
  bool _isSuccess = false;
  String? _selectedItem;

  final List<Map<String, dynamic>> _items = [
    {'name': 'Pato', 'emoji': '🦆', 'isCorrect': true, 'sound': '¡Pato! Empieza con /p/.'},
    {'name': 'Sol', 'emoji': '🌞', 'isCorrect': false, 'sound': 'Sol empieza con /s/.'},
    {'name': 'Manzana', 'emoji': '🍎', 'isCorrect': false, 'sound': 'Manzana empieza con /m/.'},
  ];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttsService.speak('Toca el dibujo que empieza con ${widget.targetPhoneme}.');
    });
  }

  void _onItemTapped(Map<String, dynamic> item) {
    if (_isSuccess) return;

    final isCorrect = item['isCorrect'] as bool;
    final itemSound = item['sound'] as String;

    setState(() {
      _selectedItem = item['name'] as String;
    });

    if (isCorrect) {
      // Disparo inmediato de audio fonético
      _ttsService.speak('¡Excelente! $itemSound');
      setState(() {
        _isSuccess = true;
      });
      widget.onComplete?.call();
    } else {
      _ttsService.speak('¡Casi! $itemSound Prueba con otro.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFCFD8DC), width: 2),
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
          const SizedBox(height: 24),

          // Opciones de discriminación auditiva
          Stack(
            alignment: Alignment.center,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _items.map((item) {
                  final isSelected = _selectedItem == item['name'];
                  final isCorrect = item['isCorrect'] as bool;

                  return Semantics(
                    label: 'Opción ${item['name']}',
                    button: true,
                    child: InkWell(
                      key: Key('match_item_${item['name']}'),
                      onTap: () => _onItemTapped(item),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
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
                                : const Color(0xFFCFD8DC),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item['emoji'] as String, style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2933)),
                              ),
                            ),
                          ],
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
                      title: '¡Muy Bien!',
                      subtitle: '¡Pato empieza con P!',
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
