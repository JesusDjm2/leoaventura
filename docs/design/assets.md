# Catálogo de Assets y Mascota "Leo" — LeoPárvulos

**Design System & Brand Assets**  
**Fase 15:** Integración de la Mascota "Leo" y Animaciones  
**Fecha:** 15 de Noviembre de 2026  

---

## 1. Identidad de la Mascota "Leo el León"

**Leo** es el compañero y guía fonoaudiológico para niños en etapa prelectora (3 a 6 años). Su diseño es redondeado, cálido y sin aristas agresivas, con tonos cálidos que armonizan con la paleta de marca:
- **Melena:** Naranja dorado (`#F57C00` / `#FE8E15`).
- **Rostro:** Amarillo amigable (`#FFD54F`).
- **Hocico:** Crema suave (`#FFF9C4`).
- **Ojos y detalles:** Azul marino oscuro (`#1A3965` / `#263238`), evitando negro puro para mayor calidez.

---

## 2. Rutas de Assets en el Repositorio

### 2.1 Componente Vectorial Dinámico e Interactivo (Flutter)
- **Código Fuente:** [leo_mascot.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/leo_mascot.dart)
- **Estados de Animación:**
  1. `MascotState.idle`: Estado de reposo con parpadeo suave y respiración imperceptible.
  2. `MascotState.talking`: Sincronización labial activa con modulación de apertura de boca (`_mouthController`).
  3. `MascotState.celebrating`: Salto festivo (`_bounceController`), boca sonriente y halo de estrellas doradas.

### 2.2 Assets Gráficos Empaquetados en la App (`client/assets/`)
Registrados en `pubspec.yaml` bajo la sección `assets: - assets/mascot/`:

| Asset | Ruta en el Cliente | Descripción / Uso | Formato / Dimensiones |
| :--- | :--- | :--- | :--- |
| **Leo Reposo** | `client/assets/mascot/leo_mascot_idle.png` | Estado base para menús y guías estáticas | PNG 32-bit (Alfa), 512×512 |
| **Leo Hablando** | `client/assets/mascot/leo_mascot_talking.png` | Boca abierta para locuciones y ayuda | PNG 32-bit (Alfa), 512×512 |
| **Leo Celebrando** | `client/assets/mascot/leo_mascot_celebrating.png` | Celebración con estrellas para diálogos de éxito | PNG 32-bit (Alfa), 512×512 |
| **Logotipo Marca** | `client/assets/brand/leoaventura_logo.png` | Logo oficial sin fondo con transparencia | PNG 32-bit, 1024×661 |

### 2.3 Evidencias Visuales de Integración UI
- **Home con Leo Guía:**
  - `docs/ui/mascot/home_screen_with_leo.png`
  - `.antigravity/evidence/home_screen_with_leo.png`
- **Diálogo de Éxito con Leo Celebrando:**
  - `docs/ui/mascot/success_dialog_with_leo.png`
  - `.antigravity/evidence/success_dialog_with_leo.png`
- **Galería de Componentes Base (Fase 14):**
  - `docs/ui/components/base_components_gallery.png`

---

## 3. Puntos de Integración en la Interfaz

1. **Pantalla Principal (Home):**
   - **Ubicación:** [home_screen.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/screens/home_screen.dart).
   - **Rol:** Guía de bienvenida en la cabecera, colocado a la izquierda del saludo.
   - **Interacción:** Al tocar a Leo, emite un saludo auditivo mediante `TtsService`.
   - **Ergonomía:** Tamaño de 84×84dp (supera el mínimo de 48dp). No interfiere ni solapa las tarjetas de actividades `activity_card_m` o `activity_card_p`.

2. **Diálogo de Logro y Éxito:**
   - **Ubicación:** [success_dialog.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/widgets/success_dialog.dart).
   - **Rol:** Celebración de meta alcanzada con estrellas.
   - **Ergonomía:** Se posiciona en la parte superior sin obstruir el botón `PrimaryButton` ni el texto de descarte.

3. **Minijuegos Fonéticos:**
   - En `sound_match_game.dart` y `letter_tracing.dart`, Leo reacciona visual y auditivamente ante los aciertos del menor.

---

## 4. Criterios de Accesibilidad y No Obstrucción

- **Áreas táctiles libres:** Todas las zonas interactivas alrededor de la mascota mantienen márgenes mínimos de seguridad (≥ 16dp de separación).
- **Contraste:** Los bordes y fondos de la mascota mantienen ratios WCAG AA (≥ 4.5:1) contra las superficies donde reposa.
- **Semántica:** Nodos semánticos claros (`button: true, label: "Mascota León Leo, tu guía de lectura. Toca para escuchar un saludo."`) para soporte con lectores de pantalla (TalkBack / VoiceOver).
