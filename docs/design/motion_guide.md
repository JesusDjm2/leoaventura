# Guía de Movimiento y Micro-Interacciones ("Juice") — Leoaventura

**Design System · Motion & Tactile Feedback**  
**Última actualización:** 17 de Noviembre de 2026  

---

## 1. Principios de Movimiento para Párvulos (3–6 años)

1. **Respuesta física inmediata (0 ms de bloqueo):** Ninguna animación debe retrasar un toque o bloquear la navegación. Los botones disparan su acción al instante mientras completan su rebote visual.
2. **Aceleración exclusiva por GPU:** Todas las transiciones animan únicamente propiedades compuestas (`transform` vía `AnimatedScale` / `SlideTransition` y `opacity` vía `FadeTransition`), garantizando **60 fps** estables sin *layout thrashing*.
3. **Empatía y calma visual:** Rebotes suaves sin sobre-oscilación agresiva (`Curves.easeOutBack`), evitando fatiga visual en niños pequeños.
4. **Accesibilidad (`prefers-reduced-motion`):** Si el sistema solicita reducir animaciones (`MediaQuery.maybeDisableAnimationsOf(context)`), las duraciones se colapsan a `Duration.zero` y las escalas permanecen en `1.0`.

---

## 2. Tabla Oficial de Duraciones y Curvas

| Interacción / Elemento | Widget / Componente | Duración | Curva de Easing | Propiedades Animadas |
| :--- | :--- | :---: | :--- | :--- |
| **Presión inicial (Shrink 5%)** | `BouncyButton`, `PrimaryButton` | **90 ms** | `Curves.easeOutCubic` | `scale: 1.0 → 0.95` |
| **Rebote al soltar (Bounce)** | `BouncyButton`, `PrimaryButton` | **150 ms** | `Curves.easeOutBack` | `scale: 0.95 → 1.0` |
| **Efecto de presión en tarjetas** | `_ActivityCard` (Home), `SoundMatchGame` | **120 ms** | `Curves.easeOutCubic` | `scale: 0.95`, borde y elevación difusa |
| **Transición de entrada de elementos** | `SlideInEntrance` (`SlideTransition` + `FadeTransition`) | **300 ms** *(por elemento)* | `Curves.easeOutCubic` | `Offset(0, 0.16) → Offset.zero`, `opacity: 0 → 1` |
| **Escalonamiento (Stagger) en Home** | `HomeScreen` (`_entranceController`) | **520 ms** *(total, ~60 ms entre bloques)* | `Interval(..., Curves.easeOutCubic)` | Entrada secuencial de banner, CTA y tarjetas |
| **Apertura de diálogo de éxito** | `SuccessDialog.show` | **280 ms** | `Curves.easeOutBack` | `ScaleTransition(0.85 → 1.0)` + `FadeTransition` |
| **Cambio de ánimo de mascota Rive** | `<AnimatedLeo />` | **200–220 ms** | `Curves.easeOutCubic` | Blending de State Machine (`idle` / `happy` / `sad`) |

---

## 3. Componentes de Movimiento Reutilizables

### `BouncyButton` ([bouncy_button.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/bouncy_button.dart))
- Encoge un **5%** (`pressedScale: 0.95`) al recibir `pointer down` y rebota en **150 ms** al soltar.
- Modo dual:
  - Con `onTap`: actúa como `GestureDetector` directo.
  - Sin `onTap`: actúa como observador pasivo `Listener` para envolver botones internos (`InkWell`, `OutlinedButton`, `PrimaryButton`) sin interferir en el `GestureArena` ni añadir latencia.

### `SlideInEntrance` ([slide_in_entrance.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/slide_in_entrance.dart))
- Impulsada por un único `AnimationController` maestro mediante `Interval(begin, end)` (cero timers pendientes en memoria ni en tests).
- No envuelve a los hijos en `IgnorePointer`: las tarjetas y botones de `HomeScreen` responden incluso si el niño los toca en los primeros 60 ms de la transición de entrada.

---

## 4. Verificación y Evidencia
- **Tests deterministas (`ui_review` + no bloqueo):** [juice_motion_test.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/test/widgets/juice_motion_test.dart).
- **Video demostrativo (30 fps reales de Flutter):**
  - [leoaventura_juice_demo.mp4](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/design/motion/leoaventura_juice_demo.mp4)
  - Copia en [.antigravity/evidence/motion/](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/.antigravity/evidence/motion/leoaventura_juice_demo.mp4).
