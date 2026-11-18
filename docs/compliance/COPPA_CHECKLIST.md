# Checklist de Cumplimiento COPPA y Privacidad Infantil — LeoPárvulos

**Normativa:** COPPA (Children's Online Privacy Protection Act) & Políticas de Familias (Google Play / App Store)  
**Última actualización:** 17 de Noviembre de 2026  

---

## Controles Verificados

- [x] **Cero PII en logs y respuestas de API:** Validado con `php artisan pii:scan` (0 hallazgos de severidad Alta en backend Laravel y cliente Flutter; ver [pii_audit.md](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/docs/compliance/pii_audit.md)).
- [x] **Aislamiento estricto de perfiles:** Middleware `child.owner` (`EnsureChildBelongsToParent`) impide el acceso cruzado entre padres (HTTP 403 verificado en `AuthTest` y `SyncProgressTest`).
- [x] **Compuerta parental (Parental Gate):** Ajustes y exportación de reportes protegidos mediante desafío matemático adulto en `ParentSettingsScreen`.
- [x] **Sin SDKs publicitarios ni de rastreo:** Cero inicialización de redes publicitarias o analítica de terceros antes del consentimiento parental.
- [x] **Crash reporting configurado con filtro de PII.**

---

## Detalle de Observabilidad Segura (Fase 17)

1. **Consentimiento explícito (Opt-In):**
   - En Flutter (`SafeCrashReporter`), `hasPrivacyConsent` inicia siempre en `false`. Ningún reporte se transmite hasta que el padre/tutor acepta explícitamente los términos de privacidad (`setPrivacyConsent(true)`).
   - En Laravel (`bootstrap/app.php` + `CrashReporter`), las excepciones solo se reportan si la petición incluye consentimiento explícito (`X-Privacy-Consent: accepted`).
2. **Filtro Scrubber (`beforeSend`):**
   - Implementado en [PiiScrubber.php](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/app/Support/Observability/PiiScrubber.php) (Laravel) y [pii_scrubber.dart](file:///C:/Users/miran/.gemini/antigravity/scratch/leo-parvulos/client/lib/observability/pii_scrubber.dart) (Flutter).
   - Sustituye sistemáticamente correos electrónicos, nombres propios, tokens Bearer, contraseñas, direcciones IP, teléfonos e identificadores de dispositivo por `[REDACTED]`, y elimina el bloque `user` antes de cualquier transmisión.
3. **Verificación Determinista:**
   - Backend: `tests/Unit/CrashReportingScrubberTest.php` (3/3 en verde).
   - Cliente: `client/test/observability/crash_reporter_test.dart` (3/3 en verde).
