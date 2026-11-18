# Guía de Animaciones Rive y State Machines — LeoPárvulos

**Módulo:** `client/lib/widgets/animated_leo.dart` (`<AnimatedLeo />`)  
**Asset Rive:** `client/assets/animations/leo_mascot.riv`  
**Dependencia:** `rive: ^0.13.20`  
**Última actualización:** 17 de Noviembre de 2026  

---

## 1. Arquitectura de `<AnimatedLeo />`

`<AnimatedLeo state="idle" />` encapsula un artboard de Rive controlado por `StateMachineController` dentro de un `RepaintBoundary` dedicado para mantener **60 fps estables** sin provocar repintados innecesarios en el árbol de widgets padre.

### Estados Emocionales (Enfoque Pedagógico No Punitivo)

| Valor de `state` | Índice numérico (`state` / `Level`) | Booleanos (`isHappy` / `isSad`) | Cuándo se dispara | Comportamiento esperado |
| :--- | :---: | :---: | :--- | :--- |
| **`"idle"`** | `0.0` | `false / false` | Inicio de actividad, reinicio o comienzo de nuevo trazo | Respiración suave y parpadeo amigable |
| **`"happy"`** | `1.0` | `true / false` | Acierto del niño (trazo completado o fonema correcto) | Salto festivo, sonrisa amplia, celebración |
| **`"sad"`** | `2.0` | `false / true` | Error o intento incompleto | Expresión **empática y suave** (*"¡Casi! Tú puedes"*), nunca punitiva ni estridente |

---

## 2. Cómo Exportar Animaciones desde Rive Editor

Sigue esta convención al crear o actualizar la mascota en [rive.app](https://rive.app):

1. **Artboard principal:**
   - Tamaño recomendado: `512 × 512 px` (cuadrado, centrado en `(256, 256)` para escalar sin recortes en `BoxFit.contain`).
   - Evita máscaras complejas o sombras con blur excesivo que impacten el rendimiento en gama baja.
2. **Crear la State Machine:**
   - Nombre recomendado: **`LeoStateMachine`** (si el archivo tiene otro nombre, `AnimatedLeo` selecciona automáticamente la primera State Machine disponible en el artboard).
3. **Configurar los Inputs (elige cualquiera de estos contratos soportados automáticamente por `AnimatedLeo`):**
   - **Opción A (Recomendada — Input Numérico):**
     - `Number` llamado **`state`** (o `mood` / `Level`):
       - `0` → transición a `Idle`
       - `1` → transición a `Happy`
       - `2` → transición a `Sad`
   - **Opción B (Inputs Booleanos + Triggers):**
     - `Boolean` **`isHappy`** y `Boolean` **`isSad`**
     - Opcionalmente `Trigger` **`happy`** y `Trigger` **`sad`** para micro-reacciones puntuales.
4. **Transiciones suaves (Blending):**
   - Configura **Duration: `200ms – 300ms`** en las flechas de transición entre `Idle ↔ Happy` e `Idle ↔ Sad` para lograr interpolación fluida sin saltos bruscos.
   - Evita dejar pistas de salida sin retorno si usas `Trigger` (`Exit Time = 100%` de vuelta a `Idle`).
5. **Exportar el archivo `.riv`:**
   - En Rive Editor: **Export → Download → For newest runtime (`.riv`)**.
   - Reemplaza el archivo en `client/assets/animations/leo_mascot.riv`.
   - Verifica que `client/pubspec.yaml` incluye:
     ```yaml
     flutter:
       assets:
         - assets/animations/
     ```

---

## 3. Cómo Conectar `<AnimatedLeo />` en Flutter

### Uso Declarativo Básico
```dart
AnimatedLeo(
  state: _leoState, // 'idle', 'happy' o 'sad'
  size: 96,
  showMoodBadge: true,
)
```

### Conexión a Eventos de un Minijuego
```dart
String _leoState = AnimatedLeoStateName.idle;

void _onChildSuccess() {
  setState(() => _leoState = AnimatedLeoStateName.happy);
}

void _onChildGentleRetry() {
  // Feedback empático: acompaña sin castigar
  setState(() => _leoState = AnimatedLeoStateName.sad);
}
```

Ya se encuentra integrado en:
- **Emparejamiento Auditivo:** [sound_match_game.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/sound_match_game.dart) (`Key('sound_match_animated_leo')`).
- **Trazado Táctil:** [letter_tracing.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/letter_tracing.dart) (`Key('tracing_animated_leo')`).

---

## 4. Rendimiento a 60fps y Accesibilidad

1. **Aislamiento de GPU (`RepaintBoundary`):** `<AnimatedLeo />` envuelve el lienzo `Rive` en un `RepaintBoundary` independiente, evitando que los 60 ticks/seg de la animación invaliden el árbol de layout del minijuego.
2. **Accesibilidad (`prefers-reduced-motion`):** Si el dispositivo tiene activada la reducción de animaciones (`MediaQuery.maybeDisableAnimationsOf(context)`), `<AnimatedLeo />` degrada automáticamente a la representación vectorial estática `LeoMascot` sin pérdida de significado semántico.
3. **Verificación en DevTools y Tests:**
   - Suite automatizada: [animated_leo_rive_test.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/test/widgets/animated_leo_rive_test.dart) valida:
     - Transiciones deterministas `idle → happy → sad` sobre el `StateMachineController` real de Rive.
     - Integración con aciertos y fallos empáticos en `SoundMatchGame`.
     - Presupuesto de renderizado de 60 frames consecutivos por debajo de `16.67 ms/frame` (60fps sin jank).
   - En perfilado manual con Flutter DevTools (`Performance → Frame Chart`), confirma que las barras de UI y Raster se mantienen por debajo de la línea verde de `16ms`.
