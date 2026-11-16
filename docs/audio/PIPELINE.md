# Pipeline de producción de audio — LeoPárvulos

> **Estado de la Fase 9: ABIERTA, pendiente de validación humana.**
> El pipeline técnico (script, manifiesto, endpoint y tests) está terminado y verificado.
> La fase **no se considera cerrada** hasta que una especialista firme la
> [checklist de validación humana](#6-checklist-de-validación-humana-obligatoria).
>
> ⚠️ Los clips de `assets/audio/v1/` son **tonos sintéticos de prueba** generados con
> ffmpeg (`tests/fixtures/audio/raw/`), no voz. Hay que reemplazarlos por grabaciones
> reales antes de publicar.

---

## 1. Flujo

```
Grabación (WAV 48 kHz / 24 bit)          assets/audio/raw/<categoria>/<nombre>.wav   (no versionado)
        │
        ▼  scripts/normalize_audio.sh --batch assets/audio/raw --trim
Normalización -16 LUFS + Opus + AAC      assets/audio/v1/<categoria>/<nombre>.{opus,m4a}
        │
        ▼  php artisan audio:manifest
Manifiesto con SHA-256 por archivo       assets/audio/v1/manifest.json
        │
        ▼
GET /api/audio/manifest                  → la app compara manifest_hash y descarga lo nuevo
GET /api/audio/v1/<categoria>/<archivo>?sha256=<hash>
```

## 2. Estructura de carpetas

```
assets/audio/
├── raw/                    # masters originales (WAV); fuera de git, respaldar aparte
└── v1/                     # catálogo publicado, versión 1
    ├── fonemas/            # sonidos aislados: /m/, /s/, /a/, /p/ ...
    ├── palabras/           # palabras completas: "mamá", "sapo" ...
    ├── instrucciones/      # consignas para el niño: "Traza la letra..."
    ├── mascota/            # voz/efectos de la mascota: saludos, celebraciones
    └── manifest.json       # generado; no editar a mano
```

Se crea una carpeta `v2/` (y se sube `AUDIO_VERSION`) solo cuando cambia algo
**incompatible**: otra voz, otro formato u otra estructura. Regrabar un clip dentro de
`v1` está permitido: cambia su hash y el `manifest_hash`, y los clientes lo vuelven a
descargar.

## 3. Convención de nombres

`<prefijo>_<identificador>.<ext>`: snake_case, **ASCII en minúsculas**, sin tildes,
sin `ñ` y sin espacios. Regex: `^[a-z0-9]+(_[a-z0-9]+)*$`.

| Categoría | Prefijo obligatorio | Ejemplos |
|---|---|---|
| `fonemas` | `fonema_` | `fonema_m`, `fonema_s`, `fonema_a`, `fonema_rr`, `fonema_ch`, `fonema_nn` (ñ) |
| `palabras` | `palabra_` | `palabra_mama`, `palabra_sapo`, `palabra_ninno` (niño) |
| `instrucciones` | `instruccion_` | `instruccion_traza_letra`, `instruccion_toca_imagen`, `instruccion_muy_bien` |
| `mascota` | `mascota_` | `mascota_saludo`, `mascota_celebra_1`, `mascota_animo_2` |

- Las vocales con tilde pierden la tilde: `mamá` → `mama`. La `ñ` se escribe `nn`,
  para no confundir palabras como `niño`/`nino`: `palabra_ninno`, `fonema_nn`.
- Las variantes de un mismo mensaje llevan sufijo numérico: `_1`, `_2`, ...
- El id del clip en el manifiesto es `<categoria>/<nombre>` (p. ej. `fonemas/fonema_m`).
- Cada clip debe existir en **los dos formatos**: `audio:manifest` falla si falta uno,
  si un nombre rompe la convención o si hay extensiones no permitidas.

## 4. Proceso de grabación

### 4.1 Quién graba

| Rol | Responsable | Notas |
|---|---|---|
| Voz principal (fonemas, palabras, instrucciones) | **[por definir]** | Una sola voz para todo el catálogo `v1`, para que el niño asocie el sonido a una voz estable. Español de Chile, dicción neutra y ritmo pausado. |
| Voz de la mascota | **[por definir]** | Puede ser la misma persona con otro registro. |
| Dirección y revisión fonoaudiológica | **[especialista por definir]** | Firma la checklist de la sección 6. |
| Operador/a técnico/a | **[por definir]** | Ejecuta el script y `audio:manifest` y sube los cambios. |

### 4.2 Equipo (recomendado; registrar el que se use realmente)

| Elemento | Recomendación | Usado en v1 |
|---|---|---|
| Micrófono | Condensador cardioide de diafragma grande (USB o XLR), con filtro antipop | **[registrar modelo]** |
| Interfaz | Si es XLR: interfaz con preamplificador limpio y phantom 48 V | **[registrar]** |
| Sala | Cuarto pequeño tratado (cortinas gruesas o paneles), sin eco ni ruido de calle; ruido de fondo < -60 dBFS | **[registrar]** |
| Distancia | 15–20 cm del micrófono, levemente fuera de eje para las plosivas (/p/, /t/) | |
| Formato | WAV, 48 kHz, 24 bit, mono | |
| Nivel | Picos entre -12 y -6 dBFS; nunca clip | |

### 4.3 Cómo grabar cada clip

1. Deja unos 0,5 s de silencio antes y después de cada toma: `--trim` los recorta.
2. **Fonemas**: sonido aislado y sostenido cuando es continuo (/m/, /s/, /a/: ~0,8–1 s).
   Las oclusivas (/p/, /t/, /k/) se graban como impulso breve, **sin vocal de apoyo**
   ("p", no "pe").
3. Graba 3 tomas por clip y elige la mejor. Nombra el archivo final según la sección 3
   y déjalo en `assets/audio/raw/<categoria>/`.

### 4.4 Script

```bash
# Requisitos: bash (Git Bash en Windows) + ffmpeg con libopus
#   Windows: winget install Gyan.FFmpeg     macOS: brew install ffmpeg     Debian/Ubuntu: apt install ffmpeg
scripts/normalize_audio.sh --batch assets/audio/raw --trim        # todo el lote
scripts/normalize_audio.sh --trim toma.wav fonemas fonema_m        # un clip
FFMPEG=/ruta/a/ffmpeg scripts/normalize_audio.sh ...               # ffmpeg fuera del PATH
php artisan audio:manifest                                         # regenerar manifiesto
php artisan audio:manifest --strict                                # además falla con audios duplicados
```

Qué hace `normalize_audio.sh` con cada clip:

| Paso | Detalle |
|---|---|
| Recorte (`--trim`) | Quita el silencio inicial y final con umbral **relativo**: pico de la toma − 40 dB. Así no se borran tomas grabadas bajas. Se hace **antes** de medir: en clips cortos el silencio sobrante altera la medición. |
| Medición | EBU R128 (`ebur128`): loudness integrado y true peak. |
| Normalización | Ganancia lineal exacta hasta **-16 LUFS**. No se usa `loudnorm` para aplicarla porque con entradas de menos de 3 s (todos los fonemas) cae a modo dinámico y no llega al objetivo. |
| Techo | Si el pico resultante pasa de **-1.5 dBTP**, se aplica un limitador y se avisa. |
| Opus | `libopus`, 48 kbps, `-application voip`, 48 kHz mono → `.opus` (Android, Web) |
| AAC | AAC-LC 64 kbps, 48 kHz mono, `+faststart` → `.m4a` (iOS, Safari) |
| Reproducible | `-map_metadata -1` y `+bitexact`: la misma entrada produce el mismo archivo y el mismo hash, así que regenerar no invalida cachés sin motivo. |

Verificación hecha con los clips de prueba (5 clips, 10 archivos): todos quedaron entre
**-16.1 y -15.9 LUFS**, con true peak ≤ -4.9 dBFS. Dos ejecuciones dieron hashes idénticos.

## 5. Manifiesto y API

`php artisan audio:manifest [--audio-version=N] [--root=DIR] [--strict]` escribe
`assets/audio/v{N}/manifest.json` de forma atómica:

```json
{
  "schema": 1,
  "version": 1,
  "manifest_hash": "6519fba5…",
  "clip_count": 5,
  "clips": {
    "fonemas/fonema_m": {
      "category": "fonemas",
      "name": "fonema_m",
      "files": {
        "aac":  { "path": "fonemas/fonema_m.m4a",  "bytes": 8338, "sha256": "…" },
        "opus": { "path": "fonemas/fonema_m.opus", "bytes": 6987, "sha256": "…" }
      }
    }
  }
}
```

- El manifiesto es determinista: no incluye fecha y las claves van ordenadas.
  `manifest_hash` es el SHA-256 del bloque `clips`.

| Endpoint | Respuesta | Caché |
|---|---|---|
| `GET /api/audio/manifest` | 200 JSON; **304** si `If-None-Match` coincide; 503 si no se generó | `public, max-age=300, must-revalidate` + `ETag: "<manifest_hash>"` |
| `GET /api/audio/v{n}/{categoria}/{archivo}?sha256=<hash>` | 200 audio (`audio/ogg` o `audio/mp4`); 404 para rutas o nombres fuera de la convención | Con el hash vigente: `public, max-age=31536000, immutable`. Sin hash o con uno viejo: `public, max-age=300, must-revalidate`. |

Ambos endpoints son públicos (sin Sanctum): no exponen datos personales, y la app
necesita las instrucciones antes del login.

Configuración en `config/audio.php`: `AUDIO_ROOT`, `AUDIO_VERSION` y `AUDIO_MANIFEST_MAX_AGE`.

Tests: `tests/Feature/AudioManifestTest.php` (8 tests).

## 6. Checklist de validación humana (obligatoria)

La fase se cierra solo cuando estos campos estén completos **con grabaciones reales**,
no con los tonos de prueba. Revisar cada clip normalizado (`.opus` y `.m4a`) con audífonos
y en un teléfono o tablet real.

| Fonema | Archivo | Criterio | Revisado por | Fecha | Firma | OK |
|---|---|---|---|---|---|---|
| /m/ | `fonemas/fonema_m` | Nasal bilabial sostenida, sin vocal añadida | [especialista] | [fecha] | | ☐ |
| /s/ | `fonemas/fonema_s` | Fricativa alveolar clara, sin ceceo ni silbido excesivo tras la compresión | [especialista] | [fecha] | | ☐ |
| /a/ | `fonemas/fonema_a` | Vocal abierta estable, sin diptongar | [especialista] | [fecha] | | ☐ |
| /p/ | `fonemas/fonema_p` | Oclusiva sorda breve, sin "pe" ni golpe de aire (pop) | [especialista] | [fecha] | | ☐ |

Comprobaciones comunes a los cuatro:

- [ ] Volumen homogéneo entre clips (sin saltos al pasar de uno a otro)
- [ ] Sin cortes al inicio ni al final (el `--trim` no se comió el ataque ni la cola)
- [ ] Sin ruido de fondo, clics ni distorsión audibles
- [ ] Igual de inteligible en Opus y en AAC

> **Fonemas /m/, /s/, /a/, /p/ revisados por [especialista] el [fecha].**
>
> Firma: ______________________

Hasta que esta línea tenga nombre, fecha y firma, la Fase 9 sigue **abierta**.
