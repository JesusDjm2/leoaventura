import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../observability/observability.dart';
import '../services/session_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/leo_mascot.dart';
import '../widgets/primary_button.dart';

export '../services/session_sync_service.dart' show AppSessionState, SyncedProgressEntry;

/// Flujo E2E completo de Registro / Inicio de Sesión Parental (Sanctum),
/// Creación de Perfil Infantil y Sincronización Multi-Dispositivo (`GET /api/progress`).
class ParentRegistrationFlowScreen extends StatefulWidget {
  static const routeName = '/register-flow';

  final String? apiBaseUrl;
  final http.Client? httpClient;
  final bool startInLoginMode;

  const ParentRegistrationFlowScreen({
    super.key,
    this.apiBaseUrl,
    this.httpClient,
    this.startInLoginMode = false,
  });

  @override
  State<ParentRegistrationFlowScreen> createState() =>
      _ParentRegistrationFlowScreenState();
}

class _ParentRegistrationFlowScreenState
    extends State<ParentRegistrationFlowScreen> {
  final _parentNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _childNameCtrl = TextEditingController();

  late bool _isLoginMode;
  int _step = 0; // 0 = Registro/Login Padre, 1 = Crear Perfil Niño, 2 = Listo para Jugar
  bool _acceptedPrivacy = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _selectedAvatar = 'leo_lion';
  String _selectedLevel = 'inicial';
  String? _sessionToken;
  String? _createdChildName;

  late final http.Client _client;
  late final bool _ownsClient;

  String get _baseUrl => AppSessionState.resolveApiBaseUrl(widget.apiBaseUrl);

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.startInLoginMode;
    _client = widget.httpClient ?? http.Client();
    _ownsClient = widget.httpClient == null;
  }

  @override
  void dispose() {
    _parentNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _childNameCtrl.dispose();
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }

  String? _extractToken(Map<String, dynamic> body) {
    final data = body['data'];
    return (body['access_token'] ??
        body['token'] ??
        (data is Map ? (data['access_token'] ?? data['token']) : null)) as String?;
  }

  Future<void> _submitParentLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa tu correo y contraseña para iniciar sesión.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = _extractToken(body);
        AppSessionState.authToken = token;
        SafeCrashReporter.instance.setPrivacyConsent(_acceptedPrivacy);

        // Descargar automáticamente perfiles y progreso sincronizado desde la nube
        await AppSessionState.fetchSyncedProgress(
          apiBaseUrl: _baseUrl,
          client: _client,
        );

        if (!mounted) return;
        setState(() {
          _sessionToken = token;
          _createdChildName = AppSessionState.activeChildName;
          _isSubmitting = false;
        });

        // Volver a Home mostrando inmediatamente el progreso sincronizado
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = (body['message'] as String?) ??
              'Credenciales inválidas (${response.statusCode}).';
          _isSubmitting = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo conectar con el servidor Laravel ($_baseUrl).';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitParentRegistration() async {
    final name = _parentNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.length < 8) {
      setState(() {
        _errorMessage =
            'Completa nombre, correo válido y una contraseña de al menos 8 caracteres.';
      });
      return;
    }

    if (!_acceptedPrivacy) {
      setState(() {
        _errorMessage = 'Debes aceptar la política de privacidad COPPA para continuar.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/api/register');
      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = _extractToken(body);
        SafeCrashReporter.instance.setPrivacyConsent(true);
        AppSessionState.authToken = token;
        await AppSessionState.persist();

        setState(() {
          _sessionToken = token;
          _step = 1;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _errorMessage = (body['message'] as String?) ??
              'No se pudo completar el registro (${response.statusCode}).';
          _isSubmitting = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo conectar con el servidor Laravel ($_baseUrl).';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitChildProfile() async {
    final childName = _childNameCtrl.text.trim();
    if (childName.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa el nombre o alias del pequeño lector.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/api/children');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
        },
        body: jsonEncode({
          'name': childName,
          'avatar_key': _selectedAvatar,
          'reading_level': _selectedLevel,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = body['data'];
        final childId = data is Map ? (data['id'] as num?)?.toInt() : null;
        AppSessionState.activeChildId = childId;
        AppSessionState.activeChildName = childName;
        AppSessionState.activeAvatarKey = _selectedAvatar;
        await AppSessionState.persist();

        setState(() {
          _createdChildName = childName;
          _step = 2;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _errorMessage = (body['message'] as String?) ??
              'Error al crear perfil infantil (${response.statusCode}).';
          _isSubmitting = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Error de conexión al guardar el perfil del niño.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        title: const Text('Cuenta Familiar · Leoaventura'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.outlineVariant, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLoginMode) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StepChip(label: '1. Padre', active: _step == 0, done: _step > 0),
                          const SizedBox(width: 8),
                          _StepChip(label: '2. Perfil Niño', active: _step == 1, done: _step > 1),
                          const SizedBox(width: 8),
                          _StepChip(label: '3. ¡A Jugar!', active: _step == 2, done: false),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_step == 0) ...[
                      SegmentedButton<bool>(
                        key: const Key('auth_mode_switch'),
                        segments: const [
                          ButtonSegment(value: false, label: Text('Crear Cuenta')),
                          ButtonSegment(value: true, label: Text('Iniciar Sesión')),
                        ],
                        selected: {_isLoginMode},
                        onSelectionChanged: (v) => setState(() {
                          _isLoginMode = v.first;
                          _errorMessage = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_step == 0 && !_isLoginMode) _buildParentRegistrationStep(textTheme),
                    if (_step == 0 && _isLoginMode) _buildParentLoginStep(textTheme),
                    if (_step == 1) _buildChildProfileStep(textTheme),
                    if (_step == 2) _buildReadyToPlayStep(textTheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentLoginStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: LeoMascot(state: MascotState.idle, size: 86)),
        const SizedBox(height: 12),
        Text(
          'Iniciar Sesión y Sincronizar',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa con tu cuenta familiar para recuperar automáticamente el progreso de lectura en este dispositivo.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('login_email'),
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('login_password'),
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          key: const Key('login_submit_btn'),
          text: 'Iniciar Sesión y Sincronizar',
          icon: Icons.cloud_download_rounded,
          isLoading: _isSubmitting,
          onPressed: _submitParentLogin,
        ),
      ],
    );
  }

  Widget _buildParentRegistrationStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LeoMascot(
            state: MascotState.idle,
            size: 86,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Registro de Padre o Tutor',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Crea tu cuenta familiar para guardar el progreso de lectura de forma segura.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('reg_parent_name'),
          controller: _parentNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del padre o madre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('reg_parent_email'),
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('reg_parent_password'),
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña (mín. 8 caracteres)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          key: const Key('reg_privacy_checkbox'),
          value: _acceptedPrivacy,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'Acepto los términos de privacidad infantil (COPPA)',
            style: textTheme.bodySmall,
          ),
          onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          key: const Key('reg_submit_parent_btn'),
          text: 'Crear Cuenta Parental',
          icon: Icons.how_to_reg_rounded,
          isLoading: _isSubmitting,
          onPressed: _submitParentRegistration,
        ),
      ],
    );
  }

  Widget _buildChildProfileStep(TextTheme textTheme) {
    final avatars = const [
      ('leo_lion', 'León Leo', '🦁'),
      ('tito_monkey', 'Mono Tito', '🐵'),
      ('ji_giraffe', 'Jirafa Ji', '🦒'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LeoMascot(
            state: MascotState.talking,
            size: 86,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Crea el Perfil del Niño',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Solo guardamos un alias amigable y su nivel fonético (cero datos personales).',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('reg_child_name'),
          controller: _childNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre o alias del niño',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.child_care_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Text('Elige su avatar favorito:', style: textTheme.titleSmall),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: avatars.map((item) {
            final selected = _selectedAvatar == item.$1;
            return InkWell(
              key: Key('avatar_${item.$1}'),
              onTap: () => setState(() => _selectedAvatar = item.$1),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandOrange.withValues(alpha: 0.25)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: selected ? 3 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(item.$3, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'inicial', label: Text('Inicial')),
            ButtonSegment(value: 'silabas', label: Text('Sílabas')),
            ButtonSegment(value: 'palabras', label: Text('Palabras')),
          ],
          selected: {_selectedLevel},
          onSelectionChanged: (values) =>
              setState(() => _selectedLevel = values.first),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          key: const Key('reg_submit_child_btn'),
          text: 'Guardar Perfil Infantil',
          icon: Icons.check_circle_rounded,
          isLoading: _isSubmitting,
          onPressed: _submitChildProfile,
        ),
      ],
    );
  }

  Widget _buildReadyToPlayStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LeoMascot(
            state: MascotState.celebrating,
            size: 110,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Todo listo, ${_createdChildName ?? AppSessionState.activeChildName}!',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'El perfil quedó guardado de forma segura en Leoaventura. ¡Comencemos la primera aventura fonética!',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          key: const Key('reg_go_minigame_btn'),
          text: '¡Jugar Minijuego de Trazado!',
          icon: Icons.play_arrow_rounded,
          backgroundColor: AppColors.brandGreen,
          bevelColor: const Color(0xFF5D9A14),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/minigame');
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('reg_go_home_btn'),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Volver al Inicio de Leoaventura'),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;

  const _StepChip({
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.brandGreen.withValues(alpha: 0.35)
        : (active ? AppColors.brandOrange.withValues(alpha: 0.35) : AppColors.surfaceContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
