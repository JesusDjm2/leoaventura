# Sistema de Partículas de Recompensa (Flame) y Háptica — Leoaventura

**Motor de Partículas:** `flame: ^1.35.1` (uso exclusivo para efectos de partículas ligeros)  
**Motor Háptico:** `flutter_haptic_feedback: ^1.0.1` + `HapticService` (`HapticFeedback.lightImpact` / `mediumImpact`)  
**Código Fuente:**
- [confetti_overlay.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/confetti_overlay.dart)
- [haptic_service.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/services/haptic_service.dart)

---

## 1. Arquitectura y Presupuesto de Rendimiento (< 15% CPU)

Flame se utiliza **exclusivamente** para superposiciones de partículas efímeras al completar un reto pedagógico:

1. **0% CPU en reposo:** `ConfettiOverlay` solo instancia y monta `GameWidget<ConfettiFlameGame>` cuando `active == true`. Mientras el niño juega, no existe ningún game loop activo.
2. **Límites estrictos de hardware:**
   - Máximo **60 partículas por ráfaga** (`ConfettiFlameGame.maxParticlesPerBurst`, valor por defecto `36`).
   - Máximo **3 sistemas concurrentes** (`ConfettiFlameGame.maxConcurrentSystems`): si se disparan más ráfagas seguidas, la más antigua se elimina automáticamente.
   - `lifespan` acotado (`1.2s – 1.6s`), con liberación automática de `ParticleSystemComponent` al finalizar (cero fugas de memoria).
3. **No bloqueante y aislado en GPU:** Siempre envuelto en `IgnorePointer(ignoring: true)` y `RepaintBoundary` para nunca interceptar gestos táctiles ni repintar el minijuego subyacente.
4. **Accesibilidad (`prefers-reduced-motion`):** Si el dispositivo tiene desactivadas las animaciones del sistema, `ConfettiOverlay` devuelve `SizedBox.shrink()`.

---

## 2. Cómo Añadir un Nuevo Efecto Visual de Recompensa

Gracias a **`RewardEffectRegistry`** (Principio Abierto/Cerrado), puedes añadir un nuevo efecto (por ejemplo, burbujas flotantes, estrellas fugaces o chispas arcoíris) **sin modificar `ConfettiOverlay` ni `ConfettiFlameGame`**.

### Paso 1: Crear la fábrica de partículas (`RewardParticleFactory`)
Define una función que devuelva un `Particle` de Flame respetando `count`, `origin` y `lifespan <= 2.0`:

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:leo_parvulos_app/theme/app_theme.dart';

Particle buildBubblesReward(Vector2 origin, int count, math.Random random) {
  return Particle.generate(
    count: count,
    lifespan: 1.5,
    generator: (_) {
      final vx = (random.nextDouble() - 0.5) * 90;
      final vy = -120.0 - random.nextDouble() * 140.0; // Flotan hacia arriba
      final radius = 4.0 + random.nextDouble() * 6.0;

      return AcceleratedParticle(
        position: origin.clone(),
        speed: Vector2(vx, vy),
        acceleration: Vector2(0, -40),
        child: ComputedParticle(
          renderer: (canvas, particle) {
            final alpha = (1.0 - particle.progress).clamp(0.0, 0.85);
            final paint = Paint()
              ..color = AppColors.brandCyan.withValues(alpha: alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(Offset.zero, radius, paint);
          },
        ),
      );
    },
  );
}
```

### Paso 2: Registrar el efecto en `RewardEffectRegistry`
Al iniciar la app o el módulo del minijuego:

```dart
RewardEffectRegistry.register('bubbles', buildBubblesReward);
```

### Paso 3: Usarlo en cualquier pantalla o minijuego
```dart
ConfettiOverlay(
  active: _isCompleted,
  effectName: 'bubbles',
  particleCount: 28,
)
```

### Efectos Incluidos de Serie
- `'confetti'`: Rectángulos y círculos giratorios con gravedad suave en la paleta oficial de Leoaventura (`brandOrange`, `brandGreen`, `brandCyan`, dorado y coral).
- `'star_burst'`: Estallido radial de destellos dorados (`lifespan: 1.2s`).

---

## 3. Retroalimentación Háptica Emparejada

| Evento de Interacción | Método | Dónde está conectado |
| :--- | :--- | :--- |
| **Toque en botón o tarjeta** | `HapticService.lightImpact()` (`HapticFeedback.lightImpact`) | `BouncyButton`, `PrimaryButton`, `_ActivityCard` |
| **Victoria / actividad completada** | `HapticService.mediumImpact()` (`HapticFeedback.mediumImpact`) | `LetterTracing._triggerSuccess()`, `SoundMatchGame` (acierto) |

Para tests unitarios o de integración, sustituye `HapticService.instance` por un mock de `HapticController` y restaura con `HapticService.reset()` en `tearDown()` (ver [confetti_haptics_integration_test.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/test/widgets/confetti_haptics_integration_test.dart)).
