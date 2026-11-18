import 'dart:async';
import 'package:flutter/material.dart';
import '../services/session_sync_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/leo_mascot.dart';
import '../widgets/primary_button.dart';

/// Pantalla de Onboarding y Bienvenida para Párvulos y Educadores.
/// Vestida con el Design System oficial de Leoaventura (`AppColors.sky`, `AppColors.navy`),
/// audio real integrado (`ParvuloTtsService.shared`), zonas táctiles generosas
/// (>= 64x64dp) y contrastes calibrados (WCAG AA).
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

  final List<Map<String, String>> _avatars = const [
    {
      'key': 'leo_lion',
      'name': 'León Leo',
      'emoji': '🦁',
      'sound': '¡Hola, soy el León Leo!',
    },
    {
      'key': 'tito_monkey',
      'name': 'Mono Tito',
      'emoji': '🐵',
      'sound': '¡Hola, soy el Mono Tito!',
    },
    {
      'key': 'ji_giraffe',
      'name': 'Jirafa Ji',
      'emoji': '🦒',
      'sound': '¡Hola, soy la Jirafa Ji!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? ParvuloTtsService.shared;
    final savedIdx =
        _avatars.indexWhere((a) => a['key'] == AppSessionState.activeAvatarKey);
    if (savedIdx >= 0) {
      _selectedAvatar = savedIdx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ttsService.speak(
        '¡Bienvenido a Leoaventura! Toca un amigo para comenzar a jugar.',
      );
    });
  }

  void _selectAvatar(int index) {
    setState(() => _selectedAvatar = index);
    AppSessionState.activeAvatarKey = _avatars[index]['key']!;
    unawaited(AppSessionState.persist());
    _ttsService.speak(_avatars[index]['sound']!);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected = _avatars[_selectedAvatar];

    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          '¡Bienvenido a Leoaventura!',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personaje anfitrión
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.brandOrange.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brandOrange, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: selected['key'] == 'leo_lion'
                            ? const LeoMascot(state: MascotState.idle, size: 102)
                            : Text(
                                selected['emoji']!,
                                style: const TextStyle(fontSize: 64),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Elige a tu compañero',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el que más te guste para acompañarte a leer:',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
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
                        child: BouncyButton(
                          pressedScale: 0.94,
                          child: Semantics(
                            label: 'Elegir avatar ${item['name']}',
                            selected: isSelected,
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectAvatar(index),
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: 84, // Muy por encima de 48x48dp
                                  height: 84, // Muy por encima de 48x48dp
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.brandOrange.withValues(alpha: 0.35)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.navy
                                          : AppColors.brandCyan,
                                      width: isSelected ? 3.5 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.navy.withValues(alpha: 0.10),
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
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Botón de prueba de sonido
                  BouncyButton(
                    pressedScale: 0.95,
                    child: OutlinedButton.icon(
                      key: const Key('onboarding_sound_check_btn'),
                      icon: const Icon(Icons.volume_up_rounded, size: 26),
                      label: const Text(
                        'Escuchar sonido de bienvenida',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy, width: 2),
                        minimumSize: const Size.fromHeight(52), // >= 48dp
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        _ttsService.speak(
                          '¡El sonido funciona perfecto! Vamos a aprender jugando.',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón principal ¡A jugar!
                  PrimaryButton(
                    key: const Key('onboarding_start_btn'),
                    text: '¡Comenzar Aventuras!',
                    icon: Icons.play_circle_fill_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
