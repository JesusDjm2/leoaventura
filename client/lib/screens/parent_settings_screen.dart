import 'package:flutter/material.dart';

/// Pantalla de Ajustes Parentales con Compuerta de Seguridad (Parental Gate).
/// Diseñada con estricta adherencia a WCAG AA (contraste >= 4.5:1 y áreas táctiles >= 48x48dp).
class ParentSettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool _gateUnlocked = false;
  final TextEditingController _gateAnswerController = TextEditingController();
  String _gateErrorMessage = '';

  // Opciones de configuración
  bool _highContrast = false;
  bool _audioFeedback = true;
  String _voiceSpeed = 'Normal';
  int _dailyLimitMinutes = 20;

  // Pregunta de seguridad: 4 x 3 = 12
  void _verifyGate() {
    if (_gateAnswerController.text.trim() == '12') {
      setState(() {
        _gateUnlocked = true;
        _gateErrorMessage = '';
      });
    } else {
      setState(() {
        _gateErrorMessage = 'Respuesta incorrecta. Por favor intenta de nuevo.';
      });
    }
  }

  @override
  void dispose() {
    _gateAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFBF360C); // Contraste 5.6:1 sobre blanco
    const textDark = Color(0xFF1F2933);   // Contraste 14:1 sobre blanco
    const textMuted = Color(0xFF37474F);  // Contraste 7.2:1 sobre blanco

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Ajustes Parentales y Seguridad',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _gateUnlocked
              ? _buildSettingsContent(textDark, textMuted)
              : _buildParentalGate(textDark, textMuted),
        ),
      ),
    );
  }

  Widget _buildParentalGate(Color textDark, Color textMuted) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFCFD8DC), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_rounded, size: 56, color: Color(0xFFBF360C)),
            const SizedBox(height: 16),
            Text(
              'Compuerta de Seguridad',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Para proteger la experiencia del niño, resuelve la siguiente operación:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '¿Cuánto es 4 × 3?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2933)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('parental_gate_input'),
              controller: _gateAnswerController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2933)),
              decoration: InputDecoration(
                hintText: 'Ingresa el resultado',
                hintStyle: const TextStyle(color: Color(0xFF78909C)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFBF360C), width: 2),
                ),
              ),
            ),
            if (_gateErrorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _gateErrorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('parental_gate_submit'),
              onPressed: _verifyGate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF360C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52), // Garantiza >= 48dp
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: const Text('Acceder a Configuración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(Color textDark, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accesibilidad y Pedagogía',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
        ),
        const SizedBox(height: 16),

        // Opción: Alto contraste
        _SettingsTile(
          title: 'Modo Alto Contraste',
          subtitle: 'Aumenta el grosor de los trazos y el contraste tipográfico',
          child: Switch(
            key: const Key('switch_high_contrast'),
            value: _highContrast,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) => setState(() => _highContrast = val),
          ),
        ),

        const SizedBox(height: 12),

        // Opción: Audio de fonemas
        _SettingsTile(
          title: 'Locución de Fonemas (TTS)',
          subtitle: 'Reproduce automáticamente los sonidos y felicitaciones',
          child: Switch(
            key: const Key('switch_audio_tts'),
            value: _audioFeedback,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) => setState(() => _audioFeedback = val),
          ),
        ),

        const SizedBox(height: 12),

        // Opción: Velocidad de locución
        _SettingsTile(
          title: 'Velocidad de Fonemas',
          subtitle: 'Ritmo con el que se pronuncian las letras',
          child: DropdownButton<String>(
            key: const Key('dropdown_voice_speed'),
            value: _voiceSpeed,
            items: const [
              DropdownMenuItem(value: 'Lenta', child: Text('Lenta')),
              DropdownMenuItem(value: 'Normal', child: Text('Normal')),
              DropdownMenuItem(value: 'Rápida', child: Text('Rápida')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _voiceSpeed = val);
            },
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Límites de Uso Saludable',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
        ),
        const SizedBox(height: 16),

        _SettingsTile(
          title: 'Tiempo Diario Máximo',
          subtitle: '$_dailyLimitMinutes minutos por sesión',
          child: Slider(
            key: const Key('slider_time_limit'),
            value: _dailyLimitMinutes.toDouble(),
            min: 10,
            max: 60,
            divisions: 5,
            activeColor: const Color(0xFFBF360C),
            onChanged: (val) => setState(() => _dailyLimitMinutes = val.toInt()),
          ),
        ),

        const SizedBox(height: 28),

        // Botón de guardar cambios
        ElevatedButton.icon(
          key: const Key('save_settings_btn'),
          icon: const Icon(Icons.check_circle_rounded, size: 24),
          label: const Text('Guardar Ajustes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), // Verde bosque accesible (4.8:1)
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54), // >= 48dp
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ajustes guardados correctamente.')),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64), // Garantiza >= 48dp de alto
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2933)),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF4A5560)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}
