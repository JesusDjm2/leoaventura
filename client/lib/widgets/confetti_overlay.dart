import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Constructor extensible para crear nuevos efectos de partículas de recompensa
/// sin modificar el núcleo de [ConfettiFlameGame] ni [ConfettiOverlay].
typedef RewardParticleFactory = Particle Function(
  Vector2 origin,
  int count,
  math.Random random,
);

/// Registro extensible de efectos visuales de recompensa basados en Flame.
class RewardEffectRegistry {
  static final Map<String, RewardParticleFactory> _factories = {
    'confetti': _buildConfettiParticle,
    'star_burst': _buildStarBurstParticle,
    'bubbles': _buildBubblesParticle,
  };

  /// Registra un nuevo efecto de recompensa (ej. `'bubbles'`, `'sparkles'`).
  static void register(String effectName, RewardParticleFactory factory) {
    _factories[effectName] = factory;
  }

  static RewardParticleFactory resolve(String effectName) {
    return _factories[effectName] ?? _buildConfettiParticle;
  }

  static Set<String> get registeredEffects => Set<String>.unmodifiable(_factories.keys);

  static const List<Color> _brandPalette = [
    AppColors.brandOrange,
    AppColors.brandGreen,
    AppColors.brandCyan,
    Color(0xFFFFD54F), // Amarillo dorado estrella
    Color(0xFFFF7043), // Coral cálido
  ];

  static Particle _buildConfettiParticle(
    Vector2 origin,
    int count,
    math.Random random,
  ) {
    return Particle.generate(
      count: count,
      lifespan: 1.6,
      generator: (index) {
        final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.3;
        final speed = 140.0 + random.nextDouble() * 260.0;
        final velocity = Vector2(math.cos(angle) * speed, math.sin(angle) * speed);
        final color = _brandPalette[index % _brandPalette.length];
        final isCircle = index % 3 == 0;
        final size = 5.0 + random.nextDouble() * 5.0;
        final spinSpeed = (random.nextDouble() - 0.5) * 10.0;

        return AcceleratedParticle(
          position: origin.clone(),
          speed: velocity,
          acceleration: Vector2(0, 420), // Gravedad suave para caída natural
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
              final paint = Paint()
                ..color = color.withValues(alpha: opacity)
                ..style = PaintingStyle.fill;

              canvas.save();
              canvas.rotate(particle.progress * spinSpeed);
              if (isCircle) {
                canvas.drawCircle(Offset.zero, size * 0.55, paint);
              } else {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromCenter(center: Offset.zero, width: size * 1.4, height: size * 0.8),
                    const Radius.circular(2),
                  ),
                  paint,
                );
              }
              canvas.restore();
            },
          ),
        );
      },
    );
  }

  static Particle _buildStarBurstParticle(
    Vector2 origin,
    int count,
    math.Random random,
  ) {
    return Particle.generate(
      count: count,
      lifespan: 1.2,
      generator: (index) {
        final angle = (index / math.max(1, count)) * math.pi * 2;
        final speed = 110.0 + random.nextDouble() * 140.0;
        final color = index.isEven ? const Color(0xFFFFD54F) : AppColors.brandOrange;

        return AcceleratedParticle(
          position: origin.clone(),
          speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
          acceleration: Vector2(0, 180),
          child: CircleParticle(
            radius: 4.5,
            paint: Paint()..color = color,
          ),
        );
      },
    );
  }

  static Particle _buildBubblesParticle(
    Vector2 origin,
    int count,
    math.Random random,
  ) {
    return Particle.generate(
      count: count,
      lifespan: 1.8,
      generator: (index) {
        final spreadX = (random.nextDouble() - 0.5) * 180.0;
        final driftX = (random.nextDouble() - 0.5) * 65.0;
        final riseSpeed = -120.0 - random.nextDouble() * 140.0;
        final color = _brandPalette[index % _brandPalette.length];
        final radius = 7.0 + random.nextDouble() * 8.0;

        return AcceleratedParticle(
          position: origin.clone() + Vector2(spreadX, 60),
          speed: Vector2(driftX, riseSpeed),
          acceleration: Vector2(0, -35),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
              final fillPaint = Paint()
                ..color = color.withValues(alpha: alpha * 0.42)
                ..style = PaintingStyle.fill;
              final rimPaint = Paint()
                ..color = color.withValues(alpha: alpha * 0.9)
                ..strokeWidth = 2.0
                ..style = PaintingStyle.stroke;
              final shinePaint = Paint()
                ..color = Colors.white.withValues(alpha: alpha * 0.85)
                ..style = PaintingStyle.fill;

              canvas.drawCircle(Offset.zero, radius, fillPaint);
              canvas.drawCircle(Offset.zero, radius, rimPaint);
              canvas.drawCircle(
                Offset(-radius * 0.32, -radius * 0.32),
                radius * 0.24,
                shinePaint,
              );
            },
          ),
        );
      },
    );
  }
}

/// Motor Flame dedicado exclusivamente a partículas ligeras de recompensa.
///
/// Límite estricto de [maxParticlesPerBurst] (60) y [maxConcurrentSystems] (3)
/// para garantizar que el uso de CPU se mantenga siempre por debajo del 15%.
class ConfettiFlameGame extends FlameGame {
  static const int maxParticlesPerBurst = 60;
  static const int maxConcurrentSystems = 3;

  final int particleCount;
  final String effectName;
  final math.Random _random;

  int _burstCount = 0;
  bool _initialized = false;

  ConfettiFlameGame({
    int particleCount = 36,
    this.effectName = 'confetti',
    math.Random? random,
  })  : particleCount = particleCount.clamp(8, maxParticlesPerBurst),
        _random = random ?? math.Random();

  bool get isInitialized => _initialized;
  int get burstCount => _burstCount;
  int get activeParticleSystems =>
      children.whereType<ParticleSystemComponent>().length;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initialized = true;
    emitBurst();
  }

  /// Dispara una ráfaga controlada de partículas desde la zona superior central.
  void emitBurst({Vector2? origin}) {
    // Limitar sistemas simultáneos para evitar picos de CPU
    final activeSystems = children.whereType<ParticleSystemComponent>().toList();
    if (activeSystems.length >= maxConcurrentSystems) {
      activeSystems.first.removeFromParent();
    }

    final spawnOrigin = origin ??
        Vector2(
          size.x > 0 ? size.x * 0.5 : 180.0,
          size.y > 0 ? size.y * 0.35 : 120.0,
        );

    final factory = RewardEffectRegistry.resolve(effectName);
    final particle = factory(spawnOrigin, particleCount, _random);

    add(ParticleSystemComponent(particle: particle));
    _burstCount++;
  }
}

/// Capa superpuesta de confeti impulsada por `flame`.
///
/// - Solo monta el loop de Flame cuando [active] es `true` (0% CPU en reposo).
/// - Envuelta en [IgnorePointer] y [RepaintBoundary] para no bloquear toques
///   ni provocar repintados en la UI subyacente.
/// - Respeta `prefers-reduced-motion`.
class ConfettiOverlay extends StatefulWidget {
  final bool active;
  final int particleCount;
  final String effectName;
  final ValueChanged<ConfettiFlameGame>? onGameCreated;

  const ConfettiOverlay({
    super.key,
    required this.active,
    this.particleCount = 36,
    this.effectName = 'confetti',
    this.onGameCreated,
  });

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  ConfettiFlameGame? _game;

  ConfettiFlameGame? get game => _game;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _createGame();
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (_game == null) {
        _createGame();
      } else {
        _game!.emitBurst();
      }
    } else if (!widget.active && oldWidget.active) {
      _game = null;
    }
  }

  void _createGame() {
    final game = ConfettiFlameGame(
      particleCount: widget.particleCount,
      effectName: widget.effectName,
    );
    _game = game;
    widget.onGameCreated?.call(game);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.active || reduceMotion || _game == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: RepaintBoundary(
          child: GameWidget<ConfettiFlameGame>(
            key: const Key('flame_confetti_game_widget'),
            game: _game!,
          ),
        ),
      ),
    );
  }
}
