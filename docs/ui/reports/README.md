# Evidencia UI — Fase 6: Panel de Padres/Docentes

Pantalla: `client/lib/reports/parent_report_screen.dart` (ruta `/#/reportes`;
también se abre con el botón de la AppBar del juego, `Key('open_parent_report')`).
Datos: `ParentReport.mock()` (9 fonemas, 4 h 35 min de práctica).

| Archivo | Vista | Tamaño lógico |
|---|---|---|
| `parent_report_mobile.png` | Móvil, pantalla visible | 412 × 915 @2x |
| `parent_report_mobile_full.png` | Móvil, panel completo con botón Exportar PDF | 412 × 1280 @2x |
| `parent_report_web.png` | Web/escritorio (2 columnas desde 840 px) | 1440 × 900 @1x |
| `home_mobile_entry.png` | Inicio con el botón de acceso al panel (icono de gráfico) | 412 × 915 @2x |

## Cómo se generaron

1. `flutter build web --release --no-web-resources-cdn`
2. `python -m http.server 8765` sobre `client/build/web`
3. Chrome headless (`--screenshot`, perfil nuevo en cada captura para no usar un bundle cacheado).
   - Web: ventana de 1440×900.
   - Móvil: Chrome headless en Windows no acepta ventanas de menos de ~500 px de ancho,
     así que la app se carga dentro de un `<iframe>` de 412 px y la captura se recorta a
     ese ancho. Si no, Flutter maqueta a más de 412 px y la "captura móvil" no es fiel.

## Revisión de UI automatizada (equivalente a `ui_review`)

`client/test/reports/parent_report_screen_test.dart` corre en ambos viewports
(412×915 y 1440×900) las guías de accesibilidad de `flutter_test`, antes y después
de desplazar hasta el botón Exportar PDF:

| Guía | Criterio | Resultado |
|---|---|---|
| `androidTapTargetGuideline` | objetivos táctiles ≥ 48×48 dp | ✅ sin hallazgos |
| `iOSTapTargetGuideline` | objetivos táctiles ≥ 44×44 pt | ✅ sin hallazgos |
| `labeledTapTargetGuideline` | todo control tiene etiqueta semántica | ✅ sin hallazgos |
| `textContrastGuideline` | contraste de texto WCAG AA (4.5:1 / 3:1 en texto grande) | ✅ sin hallazgos |

Control negativo: con texto `#BBBBBB` sobre blanco y un objetivo táctil de 30 px,
las guías de contraste y de tamaño táctil sí fallan, así que el verde de arriba vale.

El mismo test comprueba que no hay errores de layout (`tester.takeException() == null`),
que el `BarChart` tiene un grupo por fonema con los valores mock, que mide 260 px
de alto, y que el gráfico expone una etiqueta semántica con todos los valores
(para lectores de pantalla).

Paleta del panel (contraste sobre blanco): marca `#BF360C` (5.6:1 con texto blanco),
texto `#1F2933`, texto secundario `#4A5560`. Niveles de dominio: `#2E7D32`,
`#B26A00` y `#C62828`. Estos son colores de barra (no de texto), y el nivel
también aparece escrito en la leyenda y en la etiqueta semántica.

## Hallazgo fuera de alcance

La AppBar de la pantalla de juego (Fase 4) usa texto blanco sobre `Colors.deepOrangeAccent`
(`#FF6E40`), con un contraste aproximado de 2.8:1, por debajo de AA incluso para
texto grande. No se tocó en esta fase.
