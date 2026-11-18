import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../content/content_engine.dart';
import '../reports/parent_report_screen.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/leo_mascot.dart';
import '../widgets/living_sky_backdrop.dart';
import '../widgets/primary_button.dart';
import '../widgets/slide_in_entrance.dart';
import 'onboarding_screen.dart';
import 'parent_registration_flow_screen.dart';
import 'parent_settings_screen.dart';

/// Pantalla Principal (Home / Menú Infantil) de Leoaventura.
/// Diseñada con el Design System oficial (`AppColors.sky`, naranja, verde,
/// celeste y azul marino), conectada al Motor de Contenido Dinámico de los
/// 20 fonemas (`CurriculumService`), objetivos táctiles ergonómicos (>= 48x48dp),
/// transiciones escalonadas de entrada (`SlideTransition`) y respuesta física
/// elástica (`BouncyButton`).
class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  final TtsService? ttsService;
  final CurriculumService? curriculumService;

  const HomeScreen({
    super.key,
    this.ttsService,
    this.curriculumService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _leoJumpController;
  CurriculumService? _ownedCurriculumService;
  List<CurriculumLevelModel> _levels = DefaultCurriculumCatalog.levels;
  bool _loadedFromApi = false;
  int _selectedUnit = 0; // 0 = Todas

  @override
  void initState() {
    super.initState();
    // Controlador maestro para las entradas escalonadas desde abajo (~300ms por elemento).
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _leoJumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    AppSessionState.revision.addListener(_onSessionChanged);

    final isWidgetTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.curriculumService != null || !isWidgetTest) {
      _loadLiveCurriculum();
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLiveCurriculum() async {
    final service = widget.curriculumService ??
        (_ownedCurriculumService ??= CurriculumService(
          baseUri: Uri.parse(AppSessionState.resolveApiBaseUrl()),
        ));

    try {
      final response = await service.fetchLevels();
      if (!mounted || response.levels.isEmpty) return;

      final enriched = response.levels
          .map(DefaultCurriculumCatalog.augmentLevelWithSyllables)
          .toList(growable: false);

      setState(() {
        _levels = enriched;
        _loadedFromApi = true;
      });
    } catch (_) {
      // Offline-first: mantiene el catálogo local de 20 fonemas sin bloquear al niño.
    }
  }

  @override
  void dispose() {
    AppSessionState.revision.removeListener(_onSessionChanged);
    _entranceController.dispose();
    _leoJumpController.dispose();
    _ownedCurriculumService?.dispose();
    super.dispose();
  }

  CurriculumLevelModel _levelByLetter(String letter) {
    final lower = letter.toLowerCase();
    return _levels.firstWhere(
      (l) => l.letter.toLowerCase() == lower,
      orElse: () => DefaultCurriculumCatalog.levelForLetter(lower),
    );
  }

  int _completedActivitiesCount(CurriculumLevelModel level) {
    return level.activities
        .where((a) => AppSessionState.isActivityCompleted(a.activityCode))
        .length;
  }

  Color _unitBadgeColor(int unit) {
    switch (unit) {
      case 1:
        return AppColors.brandOrange;
      case 2:
        return AppColors.brandGreen;
      case 3:
        return AppColors.brandCyan;
      default:
        return const Color(0xFFD7C4F8);
    }
  }

  Future<void> _openRegistrationFlow() async {
    unawaited((widget.ttsService ?? ParvuloTtsService.shared).stopPlayback());
    await Navigator.of(context).pushNamed(ParentRegistrationFlowScreen.routeName);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openLevel(CurriculumLevelModel level) async {
    unawaited((widget.ttsService ?? ParvuloTtsService.shared).stopPlayback());
    await Navigator.of(context).pushNamed(
      '/minigame',
      arguments: level,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final childName = AppSessionState.activeChildName;
    final levelM = _levelByLetter('m');
    final levelP = _levelByLetter('p');
    final filteredLevels = _selectedUnit == 0
        ? _levels
        : _levels.where((l) => l.unit == _selectedUnit).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/brand/leoaventura_logo.png',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_stories_rounded,
                color: AppColors.navy,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Leoaventura',
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
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
                icon: const Icon(Icons.settings_rounded, color: AppColors.navy, size: 26),
                tooltip: 'Zona de padres y educadores',
                onPressed: () {
                  (widget.ttsService ?? ParvuloTtsService.shared).stopPlayback();
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
              key: const Key('open_parent_report'),
              width: 48,
              height: 48,
              child: IconButton(
                key: const Key('home_reports_btn'),
                icon: const Icon(Icons.insights_rounded, color: AppColors.navy, size: 26),
                tooltip: 'Reporte de aprendizaje',
                onPressed: () async {
                  await (widget.ttsService ?? ParvuloTtsService.shared).stopPlayback();
                  final report = await AppSessionState.fetchParentReport();
                  if (!context.mounted) return;
                  await Navigator.of(context).pushNamed(
                    ParentReportScreen.routeName,
                    arguments: report,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: LivingSkyBackdrop(key: Key('home_living_sky')),
          ),
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Banner de bienvenida con León Leo (SlideTransition desde abajo)
                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.0,
                    endInterval: 0.58,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.brandCyan, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          BouncyButton(
                            pressedScale: 0.95,
                            onTap: () {
                              if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
                                _leoJumpController.forward(from: 0.0);
                              }
                              (widget.ttsService ?? ParvuloTtsService.shared).playClip(
                                'mascota/mascota_onb_saludo',
                                fallbackText:
                                    '¡Hola $childName! Soy Leo el león. ¿Listo para jugar y aprender hoy?',
                              );
                            },
                            semanticsLabel:
                                'Mascota León Leo, tu guía de lectura. Toca para escuchar un saludo.',
                            child: AnimatedBuilder(
                              animation: _leoJumpController,
                              builder: (context, child) {
                                final t = _leoJumpController.value;
                                final jumpY = -math.sin(t * math.pi) * 14.0;
                                final scaleX = 1.0 + math.sin(t * math.pi * 2) * 0.06;
                                final scaleY = 1.0 - math.sin(t * math.pi * 2) * 0.06;
                                return Transform.translate(
                                  offset: Offset(0, jumpY),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: const Key('home_leo_mascot'),
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.brandOrange.withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.brandOrange, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandOrange.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: LeoMascot(
                                    state: MascotState.idle,
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandGreen.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'LEOAVENTURA',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '¡Hola, $childName!',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '¿Qué letra exploramos hoy con Leo?',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Acceso directo al flujo E2E (con SlideTransition + rebote táctil)
                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.10,
                    endInterval: 0.68,
                    child: PrimaryButton(
                      key: const Key('home_register_flow_btn'),
                      text: 'Cuenta Familiar (Registro / Login)',
                      icon: Icons.family_restroom_rounded,
                      onPressed: _openRegistrationFlow,
                    ),
                  ),

                  if (AppSessionState.syncedProgress.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SlideInEntrance(
                      parentAnimation: _entranceController,
                      beginInterval: 0.16,
                      endInterval: 0.74,
                      child: Container(
                        key: const Key('home_synced_progress_card'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.brandGreen, width: 2.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cloud_done_rounded, color: AppColors.secondary, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Progreso Sincronizado (${AppSessionState.totalStars} estrellas)',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final item in AppSessionState.syncedProgress)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${item.activityId} · ${item.score} pts · ${item.stars} estrellas',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),

                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.20,
                    endInterval: 0.78,
                    child: Text(
                      'Aventuras de Lectura',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Tarjeta destacada Letra M (con Trazado + Sonido + Sílabas)
                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.26,
                    endInterval: 0.84,
                    child: _ActivityCard(
                      key: const Key('activity_card_m'),
                      letter: levelM.letter.toUpperCase(),
                      phoneme: levelM.phoneme,
                      exampleWord: levelM.exampleWord,
                      badgeColor: AppColors.brandGreen,
                      completedCount: _completedActivitiesCount(levelM),
                      totalCount: levelM.activities.length,
                      completed: AppSessionState.isActivityCompleted('act_m_tracing'),
                      onTap: () => _openLevel(levelM),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Tarjeta destacada Letra P (con Trazado + Sonido + Sílabas)
                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.34,
                    endInterval: 0.92,
                    child: _ActivityCard(
                      key: const Key('activity_card_p'),
                      letter: levelP.letter.toUpperCase(),
                      phoneme: levelP.phoneme,
                      exampleWord: levelP.exampleWord,
                      badgeColor: AppColors.brandCyan,
                      completedCount: _completedActivitiesCount(levelP),
                      totalCount: levelP.activities.length,
                      completed: AppSessionState.isActivityCompleted('act_p_tracing'),
                      onTap: () => _openLevel(levelP),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 5. Mapa Completo Dinámico de los 20 Fonemas (Motor de Contenido)
                  Column(
                    key: const Key('curriculum_map_section'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mapa de 20 Fonemas',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          Container(
                            key: const Key('curriculum_status_badge'),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _loadedFromApi
                                  ? AppColors.brandGreen.withValues(alpha: 0.40)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _loadedFromApi
                                    ? AppColors.secondary
                                    : AppColors.brandCyan,
                              ),
                            ),
                            child: Text(
                              _loadedFromApi
                                  ? '${_levels.length} fonemas · En vivo'
                                  : '${_levels.length} fonemas · Listos',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filtros pedagógicos por Unidad (ergonómicos >= 48dp)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _UnitFilterPill(
                              key: const Key('unit_filter_0'),
                              label: 'Todas (${_levels.length})',
                              selected: _selectedUnit == 0,
                              onTap: () => setState(() => _selectedUnit = 0),
                            ),
                            for (final entry in DefaultCurriculumCatalog.unitLabels.entries) ...[
                              const SizedBox(width: 8),
                              _UnitFilterPill(
                                key: Key('unit_filter_${entry.key}'),
                                label: entry.value,
                                selected: _selectedUnit == entry.key,
                                onTap: () => setState(() => _selectedUnit = entry.key),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      for (final level in filteredLevels) ...[
                        _ActivityCard(
                          key: Key('curriculum_card_${level.letter.toLowerCase()}'),
                          letter: level.letter.toUpperCase(),
                          phoneme: level.phoneme,
                          exampleWord: level.exampleWord,
                          badgeColor: _unitBadgeColor(level.unit),
                          completedCount: _completedActivitiesCount(level),
                          totalCount: level.activities.length,
                          completed: _completedActivitiesCount(level) > 0 &&
                              _completedActivitiesCount(level) == level.activities.length,
                          onTap: () => _openLevel(level),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 6. Botón para repetir Onboarding / Guía auditiva con BouncyButton
                  SlideInEntrance(
                    parentAnimation: _entranceController,
                    beginInterval: 0.42,
                    endInterval: 1.0,
                    child: BouncyButton(
                      pressedScale: 0.95,
                      child: OutlinedButton.icon(
                        key: const Key('repeat_onboarding_btn'),
                        icon: const Icon(Icons.school_rounded, size: 24),
                        label: const Text('Ver bienvenida y personajes'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.navy, width: 2),
                          minimumSize: const Size.fromHeight(52), // Garantiza >= 48dp
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          (widget.ttsService ?? ParvuloTtsService.shared).stopPlayback();
                          Navigator.of(context).pushNamed(OnboardingScreen.routeName);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _UnitFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      pressedScale: 0.95,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.brandCyan,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de minijuego con respuesta táctil física:
/// se encoge un 5% (`BouncyButton`) y comprime su elevación/borde al ser presionada.
class _ActivityCard extends StatefulWidget {
  final String letter;
  final String phoneme;
  final String exampleWord;
  final Color badgeColor;
  final bool completed;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _ActivityCard({
    super.key,
    required this.letter,
    required this.phoneme,
    required this.exampleWord,
    required this.badgeColor,
    this.completed = false,
    this.completedCount = 0,
    this.totalCount = 0,
    required this.onTap,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BouncyButton(
      pressedScale: 0.95,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: Semantics(
          label:
              'Jugar actividad de la letra ${widget.letter}, fonema ${widget.phoneme}, como en ${widget.exampleWord}',
          button: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _isPressed ? AppColors.surfaceContainerLow : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isPressed ? AppColors.brandOrange : AppColors.outlineVariant,
                width: _isPressed ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: _isPressed ? 0.06 : 0.14),
                  blurRadius: _isPressed ? 4 : 12,
                  offset: Offset(0, _isPressed ? 2 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 88), // Muy por encima de 48dp
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navy.withValues(alpha: 0.2), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            widget.letter,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
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
                              'Letra ${widget.letter} (${widget.exampleWord})',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.totalCount > 0
                                  ? 'Sonido: ${widget.phoneme} · ${widget.totalCount} juegos'
                                  : 'Sonido: ${widget.phoneme}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.completed) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: const Text(
                            'Completado ★',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (widget.completedCount > 0 && widget.totalCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.brandOrange),
                          ),
                          child: Text(
                            '${widget.completedCount}/${widget.totalCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.navy,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
