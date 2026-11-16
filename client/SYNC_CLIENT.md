# Cliente de sincronización offline-first (Flutter)

Complementa `../docs/SYNC_STRATEGY.md` (lado servidor, LWW + soft deletes).
Código en `lib/sync/`, tests en `test/sync/`.

## Flujo

```
UI ──enqueue(ProgressEvent)──► pending_sync_events (SQLite / Drift)
                                     │
        conexión recuperada ─────────┤  (ConnectivityMonitor.onStatusChange)
        timer de backoff vencido ────┤
        enqueue con red ─────────────┘
                                     ▼
                           SyncQueue.flush()  (single-flight)
                                     │  lotes FIFO de hasta batchSize (50)
                                     ▼
                         POST /api/sync/progress {"events":[...]}
             200 ──► status = synced, synced_at = now
             401/408/429/5xx/red ──► attempts++, next_attempt_at = now + backoff
             403/422 ──► status = failed (no se reintenta)
```

1. **Persistir primero**: `enqueue()` siempre inserta en SQLite antes de intentar
   red; un evento nunca vive solo en memoria.
2. **Sin red**: `flush()` consulta `ConnectivityMonitor.isOnline()` y no hace nada.
3. **Al recuperar red**: el listener de `onStatusChange(true)` dispara `flush()`,
   que envía los pendientes en lote.
4. **Marcado**: con HTTP 200 se marcan como `synced` exactamente los `id` enviados
   (los eventos encolados durante la petición no se tocan).

## Estrategia de backoff

`BackoffPolicy` (`lib/sync/backoff_policy.dart`):

```
delay(n) = min(maxDelay, baseDelay × multiplier^(n−1)) × (1 ± jitter)
```

| Parámetro    | Valor por defecto | Notas |
|--------------|-------------------|-------|
| `baseDelay`  | 2 s               | |
| `multiplier` | 2                 | 2 s, 4 s, 8 s, 16 s, 32 s, … |
| `maxDelay`   | 5 min             | tope desde el intento 9 |
| `jitter`     | ±20 %             | evita que muchas tablets de un aula reintenten a la vez; `0` en tests |

- `n` = número de intentos fallidos acumulados del evento (`attempts`, ya incrementado).
- El retraso se guarda **en la fila** (`next_attempt_at`), así que sobrevive a
  reinicios de la app: `dueEvents()` solo devuelve filas con
  `next_attempt_at <= now`.
- Tras un fallo transitorio se reencola el lote entero y **se detiene el drenado**
  de esa ejecución (si el servidor devuelve 500 no tiene sentido mandar más lotes).
  Luego se programa un `Timer` para el `MIN(next_attempt_at)` de los pendientes.
- Recuperar la conexión **no** salta el backoff: solo se envían los eventos vencidos.
- No hay límite de intentos: un evento de progreso infantil nunca se descarta por
  errores transitorios; el tope de 5 min acota el coste.

### Clasificación de errores (`SyncException.isRetryable`)

| Respuesta | Tratamiento |
|-----------|-------------|
| Red caída / timeout (sin respuesta) | reintento con backoff |
| 401 | reintento (el token puede renovarse mientras tanto) |
| 408, 429, 5xx | reintento con backoff |
| 403, 422 y otros 4xx | `failed` permanente, con `last_error` para diagnóstico |

> Ojo: el servidor procesa el lote en una transacción, así que un 403/422 marca
> como `failed` el lote completo, incluidos eventos válidos.

## Concurrencia

- `flush()` es **single-flight**: si ya hay una ejecución en curso, devuelve ese
  mismo `Future` y activa `_rerunRequested`; al terminar el drenado se repite el
  ciclo para recoger eventos que llegaron durante la petición.
- `_inFlight` se libera en el `finally` **sin `await`** entre la última
  comprobación de `_rerunRequested` y la liberación, para que ninguna llamada a
  `flush()` se pierda (Dart es monohilo: no hay ventana de carrera).
- Los disparos internos (`enqueue`, conectividad, timer) usan `_trigger()`, que
  captura errores y los envía a `onError`, así que no quedan futures sin manejar.
- Supuesto: **una sola instancia de `SyncQueue` por base de datos** (un isolate).

## Esquema de la tabla local `pending_sync_events`

Definida en `lib/sync/sync_database.dart` (Drift, `schemaVersion = 1`).

| Columna           | Tipo SQLite | Nulo | Default     | Descripción |
|-------------------|-------------|------|-------------|-------------|
| `id`              | INTEGER PK AUTOINCREMENT | no | — | Orden FIFO |
| `child_id`        | INTEGER     | no   | —           | Perfil del niño |
| `activity_id`     | TEXT        | no   | —           | p. ej. `VOCAL_A_TRAZO` |
| `score`           | INTEGER     | no   | —           | 0–100 |
| `stars`           | INTEGER     | sí   | —           | 0–3 |
| `metadata`        | TEXT        | sí   | —           | Objeto JSON serializado |
| `updated_at`      | TEXT        | no   | —           | ISO 8601 UTC, clave LWW |
| `deleted_at`      | TEXT        | sí   | —           | ISO 8601 UTC, soft delete |
| `status`          | TEXT        | no   | `'pending'` | `pending` \| `synced` \| `failed` |
| `attempts`        | INTEGER     | no   | `0`         | Intentos fallidos acumulados |
| `next_attempt_at` | INTEGER     | no   | `0`         | Epoch ms; no enviar antes de este instante |
| `last_error`      | TEXT        | sí   | —           | Último error (código + cuerpo) |
| `created_at`      | INTEGER     | no   | —           | Epoch ms de inserción local |
| `synced_at`       | INTEGER     | sí   | —           | Epoch ms de confirmación del servidor |

Índice: `idx_pending_sync_due (status, next_attempt_at)`, para la consulta de
eventos vencidos.

Las filas `synced` se conservan como historial; `SyncDatabase.purgeSynced(olderThanMs)`
permite limpiarlas.

Tras cambiar la tabla hay que regenerar el código:
`dart run build_runner build`.

## Uso en la app

```dart
final queue = createProductionSyncQueue(
  baseUrl: Uri.parse(const String.fromEnvironment('API_BASE_URL')),
  tokenProvider: () async => authStore.token,
);
await queue.enqueue(ProgressEvent(childId: 1, activityId: 'VOCAL_A_TRAZO', score: 100, stars: 3));
```

## Verificación

`flutter test test/sync` usa SQLite real (`NativeDatabase.memory()`) y un
servidor HTTP real en `127.0.0.1` (`MockSyncServer`), con red, reloj y timers
simulados (`FakeConnectivity`, `FakeClock`, `FakeTimer`):

| Test | Comprueba |
|------|-----------|
| pérdida de red | 3 eventos offline → 0 peticiones → red restaurada → 1 lote con los 3 → todos `synced` |
| fallo 500 | 500 → `attempts=1`, `next_attempt_at=t0+2s`; no reintenta antes; 500 → +4s; 200 → `synced` |
| error 422 | `failed`, sin reintentos ni timers |
| concurrencia | 40 `enqueue` + `flush` simultáneos, lotes de 7 y latencia 15 ms → 40 entregas, sin duplicados |
| BackoffPolicy | secuencia 2/4/8/16/32 s, tope de 5 min, jitter dentro de ±20 % |
