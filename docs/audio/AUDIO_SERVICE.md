# AudioService (Flutter): reproducción, preload y caché

Código: `client/lib/audio/`. Tests: `client/test/audio/` (7 tests).
Catálogo y manifiesto: ver [PIPELINE.md](PIPELINE.md).

| Archivo | Responsabilidad |
|---|---|
| `audio_service.dart` | API pública: cola de reproducción, preload, interrupciones |
| `audio_cache.dart` | Caché en disco, descarga verificada por SHA-256, invalidación por manifiesto |
| `audio_manifest.dart` | Modelo del manifiesto (`GET /api/audio/manifest`) |
| `audio_focus.dart` | Interrupciones del sistema vía `audio_session` (abstraído para tests) |

## Uso

```dart
final audio = AudioService(
  cache: AudioCache(
    baseUrl: Uri.parse(const String.fromEnvironment('API_BASE_URL')),
    httpClient: http.Client(),
  ),
  focus: AudioSessionFocus(),
);
await audio.init();                                  // sesión de audio + manifiesto empaquetado

// Al arrancar o al recuperar red (el endpoint admite ETag/304):
final manifest = AudioManifest.parse(await api.getAudioManifest());
await audio.updateManifest(manifest);                // invalida la caché si cambió el hash

await audio.play('fonemas/fonema_m');                // un clip
await audio.playQueue([                              // secuencia con preload
  'instrucciones/instruccion_traza_letra',
  'fonemas/fonema_m',
]);
```

## API pública

### `AudioService`

| Miembro | Descripción |
|---|---|
| `AudioService({required AudioCache cache, required AudioFocus focus, AudioFormat? format, AudioPlayerFactory? playerFactory, AssetBundle? bundle, String bundledManifestAsset})` | `format` por defecto: AAC en iOS/macOS, Opus en el resto. `playerFactory` y `bundle` existen para inyectarlos en tests. |
| `Future<void> init()` | Configura `audio_session` (perfil *speech*), se suscribe a interrupciones y a la desconexión de audífonos, y carga `assets/audio/v1/manifest.json` si está empaquetado. |
| `Future<CacheSyncResult> updateManifest(AudioManifest m)` | Aplica el manifiesto del servidor (ver [Caché](#caché-e-invalidación)). Desde ese momento los clips se resuelven con él. |
| `Future<void> play(String clipId)` | Igual que `playQueue([clipId])`. |
| `Future<void> playQueue(List<String> clipIds)` | Reproduce en orden y cancela cualquier cola anterior. Termina cuando acaba el último clip o se llama a `stop()`. Lanza `ArgumentError` si el id no está en el manifiesto, y `AudioIntegrityException` o `AudioDownloadException` si la descarga falla. |
| `Future<void> pause()` / `resume()` | Control manual. Una pausa manual nunca se reanuda sola tras una interrupción. |
| `Future<void> stop()` | Cancela la cola y detiene ambos reproductores. |
| `String? currentClip` / `Stream<String?> currentClipStream` | Clip en curso, o `null` (sirve para resaltar la letra en la UI). |
| `AudioManifest? manifest` | Manifiesto vigente: el del servidor si ya se aplicó; si no, el empaquetado. |
| `Future<void> dispose()` | Libera reproductores y suscripciones. |

Los ids de clip son `<categoria>/<nombre>`, tal como aparecen en el manifiesto
(p. ej. `fonemas/fonema_m`).

### `AudioCache`

| Miembro | Descripción |
|---|---|
| `AudioCache({required Uri baseUrl, required http.Client httpClient, Future<Directory> Function()? rootDirectory})` | Raíz por defecto: `getApplicationDocumentsDirectory()/audio`. |
| `Future<CacheSyncResult> applyManifest(AudioManifest)` | Invalida y refresca (lo llama `updateManifest`). |
| `Future<File> ensureDownloaded(int version, AudioFileEntry)` | Devuelve el archivo en caché o lo descarga. Llamadas concurrentes para el mismo archivo comparten una sola descarga. |
| `Future<File?> cachedFile(int version, AudioFileEntry)` | Archivo en caché solo si su hash coincide. |

## Resolución de cada clip

1. **Asset empaquetado**, si el SHA-256 del archivo empaquetado coincide con el del
   manifiesto vigente. Funciona sin red desde la primera apertura.
2. **Caché en disco**: `<documentos>/audio/v{n}/<categoria>/<archivo>`.
3. **Descarga**: `GET /api/audio/v{n}/<ruta>?sha256=<hash>`. El servidor la sirve como
   inmutable, el cliente verifica el SHA-256 antes de guardar y escribe en `.part` antes
   de renombrar, así que nunca queda un clip corrupto ni a medias.

El catálogo empaquetado se actualiza con `scripts/bundle_flutter_audio.sh` (copia
`assets/audio/v1/` a `client/assets/audio/v1/`).

## Estrategia de preload

`AudioService` usa **dos `AudioPlayer` en doble buffer**:

```
clip 1   [A: cargar][A: suena ─────────────][pausa]
clip 2              [B: resolver + cargar ]   [B: suena ──────────][pausa]
clip 3                                         [A: resolver + cargar]   [A: suena…]
```

- Cuando empieza a sonar el clip *i* en un reproductor, el otro **resuelve** el clip
  *i+1* (descargándolo a caché si hace falta) y lo **carga** con
  `setAudioSource(preload: true)`. Al terminar *i*, *i+1* arranca sin latencia de
  decodificación ni de red: no hay ninguna carga entre el fin de uno y el inicio del
  otro. El test de preload lo verifica en el registro de la plataforma.
- Solo se precarga **un** clip por delante: la memoria se mantiene acotada, y la
  mayoría de las secuencias son cortas (instrucción + fonema + palabra).
- Si el preload falla (p. ej. sin red), no corta lo que está sonando: el error se
  registra y la carga se reintenta al llegar el turno de ese clip, donde el error sí
  se propaga a quien llamó.
- Al completar un clip se llama a `pause()`: `just_audio` deja `playing == true` al
  terminar, y sin esa pausa el `play()` del reproductor reutilizado no haría nada.

## Caché e invalidación

`<documentos>/audio/v{n}/index.json` guarda el `manifest_hash` aplicado y el SHA-256
de cada archivo en caché. `updateManifest(m)` hace lo siguiente:

1. Borra las carpetas de otras versiones (`v{k}` con k ≠ `m.version`).
2. Si `m.manifest_hash` es igual al aplicado, no hace nada (`unchanged`), sin red.
3. Si no, por cada archivo en caché:
   - mismo hash → se conserva;
   - hash distinto → **se borra y se vuelve a descargar** la versión nueva (la caché
     sigue caliente);
   - ya no está en el manifiesto → se borra.
4. Guarda el índice con el `manifest_hash` nuevo. La escritura es atómica y
   serializada con un lock.

Los clips que nunca se reprodujeron no se descargan por adelantado: se bajan la
primera vez que se usan, o como preload.

## Interrupciones (`audio_session`)

Los `AudioPlayer` se crean con `handleInterruptions: false`. Así hay una sola política
para los dos reproductores, gestionada por el servicio:

| Evento | Acción |
|---|---|
| Comienza interrupción `pause` (llamada, alarma, otra app) | Pausa; reanuda al terminar |
| Comienza `duck` | **Pausa** (no baja el volumen): un fonema a volumen reducido bajo otra voz es ininteligible para un niño. Reanuda al terminar. |
| Comienza `unknown` | Pausa; **no** reanuda (el sistema no garantiza que se deba reanudar) |
| Audífonos desconectados (`becomingNoisy`) | Pausa sin reanudar, para que no suene de golpe por el parlante |
| Pausa manual durante la interrupción | No se reanuda al terminar |

La sesión se configura con `AudioSessionConfiguration.speech()`.

## Tests (`client/test/audio/audio_service_test.dart`)

Usan el `AudioPlayer` **real** de `just_audio` sobre una plataforma simulada
(`FakeJustAudioPlatform`, en `audio_test_harness.dart`), porque en el host de tests no
hay motor de audio. La plataforma simulada carga el archivo real, informa la duración
y avanza la posición con timers reales. Los assets empaquetados son los reales, la caché
escribe en disco (con `path_provider` apuntando a un directorio temporal), el servidor
es un `MockClient` y las interrupciones se inyectan con `FakeAudioFocus`.

| Test | Verifica |
|---|---|
| reproducción | `play()` de un asset → el `AudioPlayer` pasa por `ready` y termina en `processingState == completed`; los bytes reproducidos tienen el SHA-256 del manifiesto; no hay peticiones de red |
| preload | Con 3 clips, cada uno ya está cargado en el otro reproductor antes de que termine el anterior, y ninguno se carga entre el fin de uno y el inicio del siguiente |
| invalidación de caché | Manifiesto con hash nuevo → el clip viejo se borra, se descarga el nuevo (con `?sha256=` nuevo), el índice se actualiza y la siguiente reproducción no usa la red. Si el manifiesto no cambia, no hay red. |
| clip eliminado / cambio de versión | Un clip que sale del manifiesto se borra; pasar a v2 borra `v1/` completa |
| integridad | Una descarga con hash distinto se rechaza y no queda en caché |
| interrupción | Llamada entrante → pausa y la posición no avanza; al terminar → reanuda y llega a `completed`. Secuencia `play → pause → play`. |
| `unknown` y audífonos | Pausan sin reanudar |

Pendiente: un `integration_test` en dispositivo o emulador real (ExoPlayer o
AVPlayer decodificando Opus/AAC de verdad). Los tests actuales validan la lógica del
servicio y su integración con `just_audio`, pero no los decodificadores nativos.
