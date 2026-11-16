import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// Pantalla de Onboarding y Bienvenida para Párvulos y Educadores.
/// Totalmente accesible para prelectores con audio TTS integrado,
/// zonas táctiles generosas (>= 64x64dp) y contrastes calibrados (WCAG AA).
class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';

  final TtsService? ttsService;

  const OnboardingScreen({super.key, this.ttsService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TtsService _ttsService;
  int _selectedAvatar = 0;

  final List<Map<String, String>> _avatars = [
    {'name': 'León Leo', 'emoji': '🦁', 'sound': '¡Hola, soy el León Leo!'},
    {'name': 'Mono Tito', 'emoji': '🐵', 'sound': '¡Hola, soy el Mono Tito!'},
    {'name': 'Jirafa Ji', 'emoji': '🦒', 'sound': '¡Hola, soy la Jirafa Ji!'},
  ];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttsService.speak('¡Bienvenido a LeoPárvulos! Toca un amigo para comenzar a jugar.');
    });
  }

  void _selectAvatar(int index) {
    setState(() => _selectedAvatar = index);
    _ttsService.speak(_avatars[index]['sound']!);
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFBF360C); // 5.6:1 sobre blanco
    const textDark = Color(0xFF1F2933);   // 14:1 sobre blanco
    const textMuted = Color(0xFF37474F);  // 7.2:1 sobre blanco

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        title: const Text(
          '¡Bienvenido a LeoPárvulos!',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personaje anfitrión
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECB3),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFA000), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _avatars[_selectedAvatar]['emoji']!,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Elige a tu compañero',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el que más te guste para acompañarte a leer:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),

              const SizedBox(height: 24),

              // Selector de Avatares táctiles de tamaño grande
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_avatars.length, (index) {
                  final isSelected = _selectedAvatar == index;
                  final item = _avatars[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Semantics(
                      label: 'Elegir avatar ${item['name']}',
                      selected: isSelected,
                      button: true,
                      child: InkWell(
                        onTap: () => _selectAvatar(index),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 84,  // Muy por encima de 48x48dp
                          height: 84, // Muy por encima de 48x48dp
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFCC80) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE65100) : const Color(0xFFCFD8DC),
                              width: isSelected ? 4 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              item['emoji']!,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Botón de prueba de sonido
              OutlinedButton.icon(
                key: const Key('onboarding_sound_check_btn'),
                icon: const Icon(Icons.volume_up_rounded, size: 26),
                label: const Text(
                  'Escuchar sonido de bienvenida',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1), // 7.5:1 contraste
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                  minimumSize: const Size.fromHeight(52), // >= 48dp
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  _ttsService.speak('¡El sonido funciona perfecto! Vamos a aprender jugando.');
                },
              ),

              const SizedBox(height: 20),

              // Botón principal ¡A jugar!
              ElevatedButton.icon(
                key: const Key('onboarding_start_btn'),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 30),
                label: const Text(
                  '¡Comenzar Aventuras!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Verde accesible (4.8:1)
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(60), // >= 48dp
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
