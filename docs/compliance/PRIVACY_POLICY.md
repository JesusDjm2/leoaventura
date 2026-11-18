# Política de Privacidad — Leoaventura (LeoPárvulos)

**Última actualización:** 17 de noviembre de 2026  
**Cumplimiento:** COPPA (Children's Online Privacy Protection Act), Google Play Families Policy y Apple App Store Kids Category.

---

## 1. Nuestro compromiso con los niños
**Leoaventura** es una aplicación educativa de lectura inicial diseñada para niños y niñas de 3 a 6 años.  
- **Sin publicidad** de terceros ni redes de anuncios.
- **Sin seguimiento conductual**, perfilado comercial ni SDKs de marketing.
- **Sin compras impulsivas accesibles a menores** ni enlaces externos sin compuerta parental aleatoria (*Parental Gate*).

## 2. Qué datos recopilamos y por qué
1. **Cuenta del adulto responsable (padre, madre o docente):**
   - Nombre y correo electrónico para autenticar la cuenta, sincronizar el progreso entre dispositivos y permitir la recuperación de contraseña.
   - La contraseña se almacena exclusivamente mediante hash criptográfico (`bcrypt` / `Argon2`).
2. **Perfil infantil (creado por el adulto):**
   - Nombre corto o alias elegido por el adulto, avatar ilustrado (`leo_lion`, etc.) y nivel de lectura inicial.
   - **No** solicitamos apellidos, fecha de nacimiento exacta, fotografías del menor, ubicación GPS, micrófono ni contactos.
3. **Progreso educativo:**
   - Actividades completadas, puntaje, estrellas y minutos estimados de práctica para generar el Panel de Padres y Docentes.

## 3. Diagnóstico técnico y reporte de fallos (Opt-in estricto)
- El reporte de errores técnicos está **desactivado por defecto**.
- Solo se activa si el adulto otorga su consentimiento explícito desde **Ajustes Parentales** (protegido por Compuerta de Seguridad).
- Antes de transmitir cualquier diagnóstico, un filtro automático (**PII Scrubber**) reemplaza cualquier posible correo, nombre o identificador por `[REDACTED]`.

## 4. Control parental y derecho de eliminación total
El adulto responsable puede en cualquier momento:
- Consultar el progreso de sus perfiles infantiles desde el **Panel de Padres y Docentes** y exportarlo en PDF.
- Revocar el consentimiento de diagnóstico técnico desde **Ajustes Parentales**.
- **Eliminar permanentemente su cuenta y todos los datos infantiles asociados** directamente dentro de la app (`Ajustes Parentales → Eliminar cuenta y todos los datos`, respaldado por `DELETE /api/user`), borrando en cascada perfiles, progreso y tokens de acceso.

## 5. Seguridad de los datos
- Toda comunicación cliente–servidor en producción utiliza cifrado **HTTPS/TLS**.
- Cada perfil infantil cuenta con aislamiento estricto de propietario (`child.owner`), impidiendo que cualquier otra cuenta acceda o modifique sus registros.
- Los endpoints de autenticación cuentan con protección contra fuerza bruta (`throttle`).

## 6. Contacto de privacidad
Para consultas sobre privacidad infantil o solicitudes de eliminación asistida, escribe a: `privacidad@leoaventura.app` *(reemplazar por tu correo oficial antes de publicar en tiendas)*.
