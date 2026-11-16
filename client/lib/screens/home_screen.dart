import 'package:flutter/material.dart';
import '../reports/parent_report_models.dart';
import '../reports/parent_report_screen.dart';
import '../services/tts_service.dart';
import '../widgets/leo_mascot.dart';
import 'onboarding_screen.dart';
import 'parent_settings_screen.dart';

/// Pantalla Principal (Home / Menú Infantil) de LeoPárvulos.
/// Diseñada con objetivos táctiles ergonómicos (>= 48x48dp), contraste WCAG AA
/// y accesibilidad reforzada para niños prelectores.
class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  final TtsService? ttsService;

  const HomeScreen({super.key, this.ttsService});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFBF360C); // Contraste 5.6:1 sobre blanco (WCAG AA)
    const textDark = Color(0xFF1F2933);   // Contraste 14:1 sobre blanco (WCAG AAA)
    const textMuted = Color(0xFF37474F);  // Contraste 7.2:1 sobre blanco (WCAG AA)

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'LeoPárvulos',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Acceso a Ajustes Parentales con área táctil mínima de 48x48dp
          Semantics(
            label: 'Zona de Padres y Ajustes',
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                key: const Key('home_settings_btn'),
                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
                tooltip: 'Zona de padres y educadores',
                onPressed: () {
                  Navigator.of(context).pushNamed(ParentSettingsScreen.routeName);
                },
              ),
            ),
          ),
          // Acceso a Progreso / Reportes con área táctil mínima de 48x48dp
          Semantics(
            label: 'Ver Reportes y Progreso',
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                key: const Key('home_reports_btn'),
                icon: const Icon(Icons.insights_rounded, color: Colors.white, size: 26),
                tooltip: 'Reporte de aprendizaje',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    ParentReportScreen.routeName,
                    arguments: ParentReport.mock(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de bienvenida con León Leo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFCFD8DC), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Mascota León Leo, tu guía de lectura. Toca para escuchar un saludo.',
                      child: GestureDetector(
                        onTap: () {
                          ttsService?.speak('¡Hola! Soy Leo el león. ¿Listo para jugar y aprender hoy?');
                        },
                        child: Container(
                          key: const Key('home_leo_mascot'),
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECB3),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFB300), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF57C00).withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: LeoMascot(
                              state: MascotState.idle,
                              size: 76,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, Mateo!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '¿Qué letra exploramos hoy?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Aventuras de Lectura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Botón grande de Minijuego de Trazado (Letra M)
              _ActivityCard(
                key: const Key('activity_card_m'),
                letter: 'M',
                phoneme: '/m/ /m/',
                exampleWord: 'Mamá',
                color: const Color(0xFF00695C), // Verde azulado oscuro: 5.8:1 contraste sobre blanco
                onTap: () {
                  Navigator.of(context).pushNamed('/minigame');
                },
              ),

              const SizedBox(height: 16),

              // Botón grande de Minijuego de Trazado (Letra P)
              _ActivityCard(
                key: const Key('activity_card_p'),
                letter: 'P',
                phoneme: '/p/ /p/',
                exampleWord: 'Papá',
                color: const Color(0xFF1565C0), // Azul profundo: 5.2:1 contraste sobre blanco
                onTap: () {
                  Navigator.of(context).pushNamed('/minigame');
                },
              ),

              const SizedBox(height: 24),

              // Botón para repetir Onboarding / Guía auditiva
              OutlinedButton.icon(
                key: const Key('repeat_onboarding_btn'),
                icon: const Icon(Icons.school_rounded, size: 24),
                label: const Text(
                  'Ver bienvenida y personajes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1), // Azul oscuro: 7.5:1
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                  minimumSize: const Size.fromHeight(52), // Garantiza >= 48dp
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(OnboardingScreen.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String letter;
  final String phoneme;
  final String exampleWord;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    super.key,
    required this.letter,
    required this.phoneme,
    required this.exampleWord,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Jugar actividad de la letra $letter, fonema $phoneme, como en $exampleWord',
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        shadowColor: Colors.black.withAlpha(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88), // Muy por encima de 48dp
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Letra $letter ($exampleWord)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sonido: $phoneme',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF37474F),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
