/// Filtro determinista de eliminación de PII (COPPA) para Flutter.
///
/// Reemplaza correos electrónicos, nombres propios, tokens, direcciones IP,
/// teléfonos e identificadores de hardware por `[REDACTED]` antes de enviar
/// cualquier reporte de crash hacia Sentry o el panel de observabilidad.
class PiiScrubber {
  static const String redacted = '[REDACTED]';

  static const Set<String> _sensitiveKeys = {
    'name',
    'nombre',
    'full_name',
    'first_name',
    'last_name',
    'child_name',
    'parent_name',
    'username',
    'email',
    'correo',
    'password',
    'password_confirmation',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'cookie',
    'ip',
    'ip_address',
    'user_ip',
    'device_id',
    'phone',
    'telefono',
    'address',
    'direccion',
    'location',
    'gps',
    'dni',
    'rut',
  };

  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    unicode: true,
  );

  static final RegExp _labeledNamePattern = RegExp(
    r'\b(nombre|name|niño|niña|child|parent|padre|madre|usuario|user|alumno|student)\s*([:=])\s*([A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]+(?:\s+[A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]+){0,2})',
    unicode: true,
    caseSensitive: false,
  );

  static final RegExp _prepositionFullNamePattern = RegExp(
    r'\b(para|de|por|for|by|of)\s+([A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]{2,}\s+[A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]{2,})',
    unicode: true,
  );

  static final RegExp _bearerTokenPattern = RegExp(
    r'\bBearer\s+[A-Za-z0-9\-._~+\/]+=*',
    caseSensitive: false,
  );

  static final RegExp _inlineSecretPattern = RegExp(
    r'\b(password|passwd|token|secret|api_key|dni|rut|device_id)\s*([:=])\s*\S+',
    caseSensitive: false,
  );

  static final RegExp _ipv4Pattern = RegExp(
    r'\b(?:\d{1,3}\.){3}\d{1,3}\b',
  );

  static final RegExp _phonePattern = RegExp(
    r'(?<!\w)(?:\+?\d{1,3}[\s\-]?)?(?:\(?\d{2,4}\)?[\s\-]?)\d{3,4}[\s\-]?\d{3,4}(?!\w)',
  );

  const PiiScrubber();

  /// Limpia texto libre sustituyendo toda PII detectada por `[REDACTED]`.
  String scrubText(String input) {
    if (input.isEmpty) return '';

    var clean = input.replaceAll(_emailPattern, redacted);

    clean = clean.replaceAllMapped(
      _labeledNamePattern,
      (m) => '${m.group(1)}${m.group(2)} $redacted',
    );

    clean = clean.replaceAllMapped(
      _prepositionFullNamePattern,
      (m) => '${m.group(1)} $redacted',
    );

    clean = clean.replaceAll(_bearerTokenPattern, 'Bearer $redacted');

    clean = clean.replaceAllMapped(
      _inlineSecretPattern,
      (m) => '${m.group(1)}${m.group(2)} $redacted',
    );

    clean = clean.replaceAll(_ipv4Pattern, redacted);
    clean = clean.replaceAll(_phonePattern, redacted);

    return clean;
  }

  /// Limpia recursivamente mapas de contexto, etiquetas o metadatos.
  Map<String, dynamic> scrubMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    data.forEach((key, value) {
      final normalized = key.trim().toLowerCase();
      if (_sensitiveKeys.contains(normalized)) {
        result[key] = redacted;
      } else {
        result[key] = _scrubValue(value);
      }
    });

    return result;
  }

  dynamic _scrubValue(dynamic value) {
    if (value is String) {
      return scrubText(value);
    }
    if (value is Map) {
      final typed = <String, dynamic>{};
      value.forEach((k, v) => typed[k.toString()] = v);
      return scrubMap(typed);
    }
    if (value is List) {
      return value.map(_scrubValue).toList(growable: false);
    }
    return value;
  }
}
