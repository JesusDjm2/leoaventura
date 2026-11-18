import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/parent_settings_service.dart';
import '../services/session_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

/// Pantalla de Ajustes Parentales con Compuerta de Seguridad Aleatoria (Parental Gate).
/// Diseñada con el Design System oficial de Leoaventura (`AppColors.sky`, `AppColors.navy`),
/// estricta adherencia a WCAG AA (contraste >= 4.5:1 y áreas táctiles >= 48x48dp)
/// y cumplimiento COPPA / Apple Kids Category.
class ParentSettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  /// Generador aleatorio inyectable para pruebas deterministas.
  final math.Random? random;

  const ParentSettingsScreen({super.key, this.random});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  late final math.Random _random;
  late int _factorA;
  late int _factorB;
  bool _gateUnlocked = false;
  final TextEditingController _gateAnswerController = TextEditingController();
  String _gateErrorMessage = '';

  // Opciones de configuración hidratadas desde almacenamiento persistente
  late bool _highContrast;
  late bool _audioFeedback;
  late String _voiceSpeed;
  late int _dailyLimitMinutes;
  late bool _crashReportingConsent;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? math.Random();
    _generateNewChallenge();
    _highContrast = ParentSettingsState.highContrast;
    _audioFeedback = ParentSettingsState.audioFeedback;
    _voiceSpeed = ParentSettingsState.voiceSpeed;
    _dailyLimitMinutes = ParentSettingsState.dailyLimitMinutes;
    _crashReportingConsent = ParentSettingsState.crashReportingConsent;
  }

  void _generateNewChallenge() {
    _factorA = 3 + _random.nextInt(7); // 3..9
    _factorB = 2 + _random.nextInt(8); // 2..9
  }

  int get _expectedAnswer => _factorA * _factorB;

  void _verifyGate() {
    if (_gateAnswerController.text.trim() == _expectedAnswer.toString()) {
      setState(() {
        _gateUnlocked = true;
        _gateErrorMessage = '';
      });
    } else {
      setState(() {
        _gateErrorMessage =
            'Respuesta incorrecta. Intenta con esta nueva operación.';
        _gateAnswerController.clear();
        _generateNewChallenge();
      });
    }
  }

  Future<void> _saveSettings() async {
    ParentSettingsState.highContrast = _highContrast;
    ParentSettingsState.audioFeedback = _audioFeedback;
    ParentSettingsState.voiceSpeed = _voiceSpeed;
    ParentSettingsState.dailyLimitMinutes = _dailyLimitMinutes;
    ParentSettingsState.crashReportingConsent = _crashReportingConsent;
    await ParentSettingsState.save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajustes guardados correctamente.')),
    );
  }

  Future<void> _handleLogout() async {
    await AppSessionState.logout();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión familiar cerrada.')),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final passwordCtrl = TextEditingController();
    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta y datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta acción borra permanentemente tu cuenta parental, perfiles infantiles y progreso. Ingresa tu contraseña para confirmar:',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('delete_account_password_input'),
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_delete_account_btn'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(passwordCtrl.text),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    passwordCtrl.dispose();

    if (confirmedPassword == null || confirmedPassword.isEmpty) return;

    final result = await AppSessionState.deleteAccount(
      password: confirmedPassword,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  void dispose() {
    _gateAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          'Ajustes Parentales y Seguridad',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _gateUnlocked
                  ? _buildSettingsContent(textTheme)
                  : _buildParentalGate(textTheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentalGate(TextTheme textTheme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brandCyan, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_rounded, size: 56, color: AppColors.navy),
          const SizedBox(height: 16),
          Text(
            'Compuerta de Seguridad',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para proteger la experiencia del niño, resuelve la siguiente operación:',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.brandCyan, width: 1.5),
            ),
            child: Text(
              '¿Cuánto es $_factorA × $_factorB?',
              key: const Key('parental_gate_question'),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('parental_gate_input'),
            controller: _gateAnswerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _verifyGate(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: 'Ingresa el resultado',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.navy, width: 2),
              ),
            ),
          ),
          if (_gateErrorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _gateErrorMessage,
              key: const Key('parental_gate_error'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            key: const Key('parental_gate_submit'),
            text: 'Acceder a Configuración',
            icon: Icons.lock_open_rounded,
            onPressed: _verifyGate,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accesibilidad y Pedagogía',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),

        // Opción: Alto contraste
        _SettingsTile(
          title: 'Modo Alto Contraste',
          subtitle: 'Aumenta el grosor de los trazos y el contraste tipográfico',
          child: Switch(
            key: const Key('switch_high_contrast'),
            value: _highContrast,
            activeThumbColor: AppColors.secondary,
            onChanged: (val) => setState(() => _highContrast = val),
          ),
        ),

        const SizedBox(height: 12),

        // Opción: Audio de fonemas
        _SettingsTile(
          title: 'Locución de Fonemas (Audio)',
          subtitle: 'Reproduce automáticamente los sonidos y felicitaciones',
          child: Switch(
            key: const Key('switch_audio_tts'),
            value: _audioFeedback,
            activeThumbColor: AppColors.secondary,
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
          'Límites Saludables y Privacidad (COPPA)',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),

        _SettingsTile(
          title: 'Tiempo Diario Máximo',
          subtitle: '$_dailyLimitMinutes minutos por sesión',
          child: SizedBox(
            width: 150,
            child: Slider(
              key: const Key('slider_time_limit'),
              value: _dailyLimitMinutes.toDouble(),
              min: 10,
              max: 60,
              divisions: 5,
              activeColor: AppColors.navy,
              onChanged: (val) => setState(() => _dailyLimitMinutes = val.toInt()),
            ),
          ),
        ),

        const SizedBox(height: 12),

        _SettingsTile(
          title: 'Diagnóstico Anónimo de Errores',
          subtitle:
              'Envía reportes técnicos sin datos personales ([REDACTED]) para mejorar la app',
          child: Switch(
            key: const Key('switch_privacy_consent'),
            value: _crashReportingConsent,
            activeThumbColor: AppColors.secondary,
            onChanged: (val) => setState(() => _crashReportingConsent = val),
          ),
        ),

        const SizedBox(height: 28),

        // Botón de guardar cambios
        ElevatedButton.icon(
          key: const Key('save_settings_btn'),
          icon: const Icon(Icons.check_circle_rounded, size: 24),
          label: const Text(
            'Guardar Ajustes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54), // >= 48dp
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _saveSettings,
        ),

        if (AppSessionState.authToken != null &&
            AppSessionState.authToken!.isNotEmpty) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('logout_family_btn'),
            icon: const Icon(Icons.logout_rounded, size: 22),
            label: const Text('Cerrar sesión familiar'),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 2),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _handleLogout,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const Key('delete_account_btn'),
            icon: const Icon(Icons.delete_forever_rounded, size: 22),
            label: const Text('Eliminar cuenta y todos los datos (COPPA)'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _handleDeleteAccount,
          ),
        ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.brandCyan, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
