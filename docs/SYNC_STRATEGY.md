# Estrategia de Sincronización Offline-First - LeoPárvulos

Este documento define la arquitectura y el protocolo de sincronización de datos entre los clientes cliente (App móvil Flutter / Tablet / PWA) y el backend Laravel para el registro de progreso y actividades pedagógicas.

---

## 1. Principio Fundamental: Offline-First

Los párvulos frecuentemente usan tablets o celulares en entornos sin conexión constante a internet (viajes, aulas escolares con conectividad intermitente, hogares). La aplicación móvil debe ser completamente funcional sin conexión:
1. Las actividades se descargan y almacenan en almacenamiento local (ej. SQLite / Hive en Flutter, IndexedDB en Web).
2. Cada interacción y resultado se almacena localmente como un **evento de progreso** con su respectiva marca de tiempo ISO 8601.
3. Cuando se detecta conectividad, el cliente envía los eventos acumulados en lote al endpoint `POST /api/sync/progress`.

---

## 2. Estrategia de Resolución de Conflictos: Last-Write-Wins (LWW)

En escenarios donde un niño practica en dos dispositivos distintos (o si un envío se retrasa por problemas de red), pueden llegar al servidor múltiples versiones del progreso para una misma actividad (`child_id` + `activity_id`).

### Algoritmo LWW:
Para cada evento recibido en el lote:
1. Se busca si ya existe un registro en la base de datos para la tupla `(child_id, activity_id)` (incluyendo registros eliminados suavemente).
2. **Si no existe:** Se inserta el nuevo registro inmediatamente con sus marcas de tiempo provistas por el cliente.
3. **Si ya existe:** Se compara `incoming.updated_at` contra `existing.updated_at`:
   - **Caso `incoming.updated_at > existing.updated_at` (Gana el nuevo):** El estado entrante es más reciente y sobreescribe los campos `score`, `stars`, `metadata`, `updated_at` y `deleted_at`.
   - **Caso `incoming.updated_at <= existing.updated_at` (Descarta el nuevo):** El servidor ya posee una versión igual o posterior; el evento entrante se ignora sin alterar el registro persistido.

---

## 3. Campos Requeridos y Estructura del Evento

Cada elemento del arreglo `events` debe contener obligatoriamente:

| Campo | Tipo | Requerido | Descripción |
| :--- | :--- | :--- | :--- |
| `child_id` | `integer` | **Sí** | Identificador del perfil del niño (debe pertenecer al padre autenticado). |
| `activity_id` | `string` | **Sí** | Código único de la actividad (ej: `"VOCAL_A_TRAZO"`, `"FONEMA_M_PRACTICA"`). |
| `score` | `integer` | **Sí** | Puntuación obtenida (0 a 100). |
| `stars` | `integer` | No | Estrellas obtenidas (0 a 3). |
| `metadata` | `object` | No | Datos adicionales de contexto (ej: `{"intentos": 2, "dispositivo": "Tablet"}`). |
| `updated_at` | `string (ISO 8601)` | **Sí** | **Crucial para LWW:** Fecha y hora exacta de la última modificación en el dispositivo local. |
| `deleted_at` | `string (ISO 8601)` | No / Nulable | **Crucial para Soft Delete:** Si el usuario reseteó o eliminó el progreso de la actividad. |

### Ejemplo de Payload (Request Body)
```json
{
  "events": [
    {
      "child_id": 1,
      "activity_id": "VOCAL_A_DISCRIMINACION",
      "score": 100,
      "stars": 3,
      "metadata": {
        "tiempo_segundos": 45,
        "errores": 0
      },
      "updated_at": "2026-11-15T19:50:00.000Z",
      "deleted_at": null
    },
    {
      "child_id": 1,
      "activity_id": "VOCAL_E_TRAZO",
      "score": 60,
      "stars": 1,
      "updated_at": "2026-11-15T19:52:10.000Z",
      "deleted_at": "2026-11-15T19:53:00.000Z"
    }
  ]
}
```

---

## 4. Política de Eliminación Suave (Soft Deletes)

* Si un evento incluye un valor en `deleted_at` y su `updated_at` es más reciente que el del servidor, el registro **no se elimina físicamente** de la tabla `activity_progress`.
* En su lugar, se asigna `deleted_at = Carbon::parse(incoming.deleted_at)`.
* Esto preserva la trazabilidad analítica y previene que una versión antigua guardada en otro dispositivo vuelva a recrear inadvertidamente un registro que el usuario decidió eliminar.

---

## 5. Garantía Transaccional y Seguridad Multi-Inquilino

1. **Atomicidad con `DB::transaction`:** Todo el lote de eventos se ejecuta dentro de una transacción. Si ocurre un error inesperado en mitad del lote, se realiza un rollback íntegro para evitar estados inconsistentes.
2. **Aislamiento Multi-Padre:** Antes de procesar cualquier evento, el servidor valida que el `child_id` pertenezca efectivamente al usuario autenticado vía token Sanctum. Si se detecta un intento de sincronizar el progreso de un niño ajeno, se cancela la transacción y se retorna un código `403 Forbidden`.
