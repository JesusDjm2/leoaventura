import 'dart:async';
import 'package:flutter/material.dart';
import 'content/content_engine.dart';
import 'observability/observability.dart';
import 'reports/parent_report_models.dart';
import 'reports/parent_report_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/parent_registration_flow_screen.dart';
import 'screens/parent_settings_screen.dart';
import 'screens/ui_playground_screen.dart';
import 'services/parent_settings_service.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/flying_stars_overlay.dart';
import 'widgets/primary_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.configureFonts();

  // Crash reporting seguro (Fase 17): bloqueado hasta aceptación explícita de privacidad.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  SafeCrashReporter.instance = SafeCrashReporter(
    transport: sentryDsn.isNotEmpty
        ? SentryHttpTransport(dsn: sentryDsn)
        : TestCrashPanelTransport(),
    initialPrivacyConsent: false,
  )..installGlobalHandlers();

  // Restaura sesión, ajustes parentales y progreso local persistido antes del primer frame.
  await Future.wait([
    AppSessionState.hydrate(),
    ParentSettingsState.hydrate(),
  ]);
  if (AppSessionState.authToken != null && AppSessionState.authToken!.isNotEmpty) {
    unawaited(AppSessionState.fetchSyncedProgress());
  }

  runApp(const LeoParvulosApp());
}

class LeoParvulosApp extends StatelessWidget {
  const LeoParvulosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leoaventura - Minijuegos de Lectura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        ParentRegistrationFlowScreen.routeName: (_) =>
            const ParentRegistrationFlowScreen(),
        '/minigame': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final level = args is CurriculumLevelModel ? args : null;
          return TracingGameScreen(level: level);
        },
        ParentReportScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final report = args is ParentReport
              ? args
              : AppSessionState.buildLocalReport();
          return ParentReportScreen(report: report);
        },
        ParentSettingsScreen.routeName: (_) => const ParentSettingsScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        UiPlaygroundScreen.routeName: (_) => const UiPlaygroundScreen(),
      },
    );
  }
}

/// Pantalla de Aventura Dinámica por Fonema.
/// Renderiza secuencialmente las actividades del nivel (`Trazar`, `Sonido` y `Sílabas`)
/// a través de [DynamicActivityHost] y sincroniza el progreso con Laravel.
class TracingGameScreen extends StatefulWidget {
  final CurriculumLevelModel? level;
  final TtsService? ttsService;

  const TracingGameScreen({
    super.key,
    this.level,
    this.ttsService,
  });

  @override
  State<TracingGameScreen> createState() => _TracingGameScreenState();
}

class _TracingGameScreenState extends State<TracingGameScreen> {
  late final CurriculumLevelModel _level;
  int _activeIndex = 0;
  int _completedCount = 0;
  bool _currentStepDone = false;
  bool _isSyncing = false;
  bool _syncedToCloud = false;
  final Set<String> _sessionCompletedCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _level = DefaultCurriculumCatalog.augmentLevelWithSyllables(
      widget.level ?? DefaultCurriculumCatalog.levelForLetter('m'),
    );
  }

  ActivityModel get _activeActivity => _level.activities[_activeIndex];

  String _stepLabel(ActivityModel activity) {
    switch (activity.type) {
      case ActivityTypes.tracing:
        return 'Trazar';
      case ActivityTypes.soundMatch:
        return 'Sonido';
      case ActivityTypes.syllableBuilder:
        return 'Sílabas';
      case ActivityTypes.wordReading:
        return 'Leer';
      default:
        return activity.title.isNotEmpty ? activity.title : 'Jugar';
    }
  }

  IconData _stepIcon(ActivityModel activity) {
    switch (activity.type) {
      case ActivityTypes.tracing:
        return Icons.edit_rounded;
      case ActivityTypes.soundMatch:
        return Icons.hearing_rounded;
      case ActivityTypes.syllableBuilder:
        return Icons.auto_awesome_rounded;
      case ActivityTypes.wordReading:
        return Icons.menu_book_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  Future<void> _handleActivityComplete(ActivityModel activity) async {
    AppSessionState.recordLocalCompletion(
      activityId: activity.activityCode,
      stars: 3,
    );

    setState(() {
      _completedCount++;
      _currentStepDone = true;
      _sessionCompletedCodes.add(activity.activityCode);
      _isSyncing = AppSessionState.authToken != null;
    });

    final ok = await AppSessionState.syncActivityCompletion(
      activityId: activity.activityCode,
      score: 100,
      stars: 3,
      metadata: {
        'letter': _level.letter,
        'activity_type': activity.type,
        'channel': 'flutter_web',
      },
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncedToCloud = ok;
      });
    }
  }

  void _selectStep(int index) {
    if (index < 0 || index >= _level.activities.length) return;
    setState(() {
      _activeIndex = index;
      _currentStepDone = false;
      _syncedToCloud = false;
    });
  }

  void _goNextOrFinish() {
    if (_activeIndex + 1 < _level.activities.length) {
      _selectStep(_activeIndex + 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activity = _activeActivity;
    final letterUpper = _level.letter.toUpperCase();
    final hasNextStep = _activeIndex + 1 < _level.activities.length;

    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brandOrange,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy, width: 1.5),
              ),
              child: Center(
                child: Text(
                  letterUpper,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Letra $letterUpper · ${_level.exampleWord}',
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const Key('open_parent_report'),
              tooltip: 'Panel de padres y docentes',
              icon: const Icon(Icons.insights_rounded, color: AppColors.navy),
              onPressed: () async {
                final report = await AppSessionState.fetchParentReport();
                if (!context.mounted) return;
                await Navigator.of(context).pushNamed(
                  ParentReportScreen.routeName,
                  arguments: report,
                );
              },
            ),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey('stars_pill_$_completedCount'),
            tween: Tween(begin: _completedCount > 0 ? 1.24 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandOrange, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    '${AppSessionState.totalStars > 0 ? AppSessionState.totalStars : _completedCount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Selector pedagógico de pasos del nivel (Trazar -> Sonido -> Sílabas)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: List.generate(_level.activities.length, (i) {
                      final step = _level.activities[i];
                      final isSelected = i == _activeIndex;
                      final isDone = _sessionCompletedCodes.contains(step.activityCode) ||
                          AppSessionState.isActivityCompleted(step.activityCode);

                      return BouncyButton(
                        pressedScale: 0.95,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: Key('activity_step_$i'),
                            onTap: () => _selectStep(i),
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              constraints: const BoxConstraints(minHeight: 48, minWidth: 104),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.navy
                                    : isDone
                                        ? AppColors.brandGreen.withValues(alpha: 0.45)
                                        : AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.navy
                                      : isDone
                                          ? AppColors.secondary
                                          : AppColors.brandCyan,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDone ? Icons.check_circle_rounded : _stepIcon(step),
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : isDone
                                            ? AppColors.secondary
                                            : AppColors.navy,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${i + 1}. ${_stepLabel(step)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  if (_isSyncing || _syncedToCloud)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        key: const Key('cloud_sync_badge'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _syncedToCloud
                              ? AppColors.brandGreen.withValues(alpha: 0.35)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _syncedToCloud ? AppColors.secondary : AppColors.outline,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _syncedToCloud ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                              color: AppColors.navy,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _syncedToCloud
                                  ? 'Progreso sincronizado en la nube (+3 estrellas)'
                                  : 'Sincronizando progreso...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Motor dinámico: renderiza LetterTracing, SoundMatchGame o SyllableBuilderGame
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.brandCyan, width: 2),
                    ),
                    child: DynamicActivityHost(
                      key: ValueKey(activity.activityCode),
                      activity: activity,
                      ttsService: widget.ttsService,
                      onComplete: () => _handleActivityComplete(activity),
                    ),
                  ),

                  if (_currentStepDone) ...[
                    const SizedBox(height: 20),
                    PrimaryButton(
                      key: const Key('next_activity_btn'),
                      text: hasNextStep
                          ? 'Siguiente: ${_stepLabel(_level.activities[_activeIndex + 1])}'
                          : '¡Letra $letterUpper completada! Volver al mapa',
                      icon: hasNextStep ? Icons.arrow_forward_rounded : Icons.map_rounded,
                      onPressed: _goNextOrFinish,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
          ),
          Positioned.fill(
            child: FlyingStarsOverlay(
              key: const Key('flying_stars_overlay'),
              triggerCount: _completedCount,
            ),
          ),
        ],
      ),
    );
  }
}
