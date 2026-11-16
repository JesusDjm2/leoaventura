# Registro de Decisiones Técnicas (ADR / Project Decisions)

- **DB local:** SQLite por velocidad. CI probará contra MySQL para paridad con producción. Entorno: Laragon (transición recomendada desde XAMPP).
- **Fecha:** 2026-11-15
- **Proyecto:** LeoPárvulos (App educativa de alfabetización para párvulos)
- **Stack Backend:** Laravel 12 (PHP 8.2) con API REST (Sanctum) y soporte para SQLite en local.
- **Autenticación (Fase 1):** Laravel Sanctum con tokens de acceso personal (Bearer Tokens) generados en login y registro.
- **Aislamiento de Perfiles (Fase 1):** Middleware `EnsureChildBelongsToParent` (`child.owner`) aplicado a rutas `/api/children/{child}` para verificar autoría, retornando HTTP 403 si un padre intenta consultar o manipular el perfil de otro padre.
- **Sincronización Offline-First (Fase 2):** Endpoint `POST /api/sync/progress` ejecutado bajo transacciones atómicas (`DB::transaction`) con estrategia de resolución de conflictos **Last-Write-Wins (LWW)** basada en `updated_at` y soporte de **Soft Deletes** (`deleted_at`). Especificado en `docs/SYNC_STRATEGY.md`.
- **Cliente Interactivo y Trazado (Fase 4):** Frontend unificado en Flutter (`client/`) con widget `<LetterTracing letter="m" />`. Utiliza `CustomPainter` con checkpoints normalizados, servicio desacoplado de audio fonético TTS (`ParvuloTtsService`), y componente celebratorio `CelebrationAnimation` con validación y captura visual automatizada.
- **Contrato de API:** Documentado en `docs/API_CONTRACT.md` con endpoints, payloads y códigos de respuesta (200, 201, 401, 403, 422).
- **Cola de sincronización cliente (Fase 5):** Flutter + Drift (SQLite), tabla `pending_sync_events`, envío en lote, backoff exponencial (2 s ×2, tope 5 min, jitter ±20 %) persistido en `next_attempt_at`, `flush()` single-flight. 401/408/429/5xx/red → reintento; 403/422 → `failed`. Especificado en `client/SYNC_CLIENT.md`.
- **Panel de Padres/Docentes (Fase 6):** `ParentReportScreen` (ruta `/reportes`) con `fl_chart` para el gráfico y `pdf` + `printing` para exportar. Accesibilidad verificada con las guías de `flutter_test` (≥48 dp, contraste AA). Evidencia en `docs/ui/reports/`. `pdf` fijado en 3.12 / `image` <4.11 por el Dart SDK 3.9.2 local.
- **Auditoría de Accesibilidad (Fase 7):** Auditoría WCAG 2.1/2.2 AA sobre las 5 pantallas principales (`HomeScreen`, `TracingGameScreen`, `ParentReportScreen`, `ParentSettingsScreen`, `OnboardingScreen`). Zonas táctiles ≥ 48×48dp, ratios de contraste de 4.8:1 a 14.2:1 y 0 violaciones A/AA. Verificado en `test/a11y/five_screens_a11y_test.dart` y documentado en `docs/accessibility/audit_v1.md`.
- **Cumplimiento COPPA y Cero PII (Fase 8):** Implementación del comando determinista `php artisan pii:scan` para escanear controladores Laravel, modelos y código cliente de Flutter. 0 hallazgos de severidad alta, cero logs de credenciales o menores, cero SDKs de terceros comerciales y compuerta parental activa. Informe firmado en `docs/compliance/pii_audit.md`.
