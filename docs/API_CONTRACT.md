# Contrato de API REST - LeoPárvulos

Especificación de los endpoints implementados y vigentes para la plataforma educativa **LeoPárvulos**. La API utiliza **Laravel Sanctum** para autenticación basada en Bearer Tokens.

- **Base URL:** `/api`
- **Formato de datos:** `application/json` (enviar cabeceras `Accept: application/json` y `Content-Type: application/json`)
- **Autenticación:** Cabecera HTTP `Authorization: Bearer <TOKEN>` (requerida para todas las rutas protegidas).

---

## 1. Autenticación de Padres / Educadores

Gestión de cuentas para los adultos responsables que supervisan el aprendizaje de los párvulos.

### 1.1 Registro de Padre/Tutor
- **Método:** `POST`
- **Ruta:** `/api/register`
- **Autenticación:** Pública

#### Request Body
```json
{
  "name": "María González",
  "email": "maria@example.com",
  "password": "Password123*",
  "password_confirmation": "Password123*",
  "device_name": "Tablet Samsung A8"
}
```

#### Respuestas
- **201 Created**
```json
{
  "message": "Usuario registrado exitosamente.",
  "data": {
    "user": {
      "id": 1,
      "name": "María González",
      "email": "maria@example.com",
      "created_at": "2026-11-15T19:30:00Z"
    },
    "token": "1|qW8y...plainTextToken"
  }
}
```
- **422 Unprocessable Content** (Error de validación)
```json
{
  "message": "El correo electrónico ya se encuentra registrado. (y 1 error más)",
  "errors": {
    "email": ["El correo electrónico ya se encuentra registrado."],
    "password": ["La confirmación de la contraseña no coincide."]
  }
}
```

---

### 1.2 Inicio de Sesión (Login)
- **Método:** `POST`
- **Ruta:** `/api/login`
- **Autenticación:** Pública

#### Request Body
```json
{
  "email": "maria@example.com",
  "password": "Password123*",
  "device_name": "Tablet Samsung A8"
}
```

#### Respuestas
- **200 OK**
```json
{
  "message": "Inicio de sesión exitoso.",
  "data": {
    "user": {
      "id": 1,
      "name": "María González",
      "email": "maria@example.com"
    },
    "token": "2|eR7u...plainTextToken"
  }
}
```
- **401 Unauthorized** (Credenciales inválidas)
```json
{
  "message": "Credenciales inválidas. Compruebe su correo y contraseña."
}
```
- **422 Unprocessable Content** (Campos requeridos faltantes)
```json
{
  "message": "El correo electrónico es obligatorio.",
  "errors": {
    "email": ["El correo electrónico es obligatorio."]
  }
}
```

---

### 1.3 Obtener Usuario Autenticado
- **Método:** `GET`
- **Ruta:** `/api/user`
- **Autenticación:** `Bearer Token` (`auth:sanctum`)

#### Respuestas
- **200 OK**
```json
{
  "data": {
    "id": 1,
    "name": "María González",
    "email": "maria@example.com"
  }
}
```
- **401 Unauthorized**
```json
{
  "message": "Unauthenticated."
}
```

---

### 1.4 Cierre de Sesión (Logout)
- **Método:** `POST`
- **Ruta:** `/api/logout`
- **Autenticación:** `Bearer Token` (`auth:sanctum`)

#### Respuestas
- **200 OK**
```json
{
  "message": "Sesión cerrada exitosamente."
}
```
- **401 Unauthorized**
```json
{
  "message": "Unauthenticated."
}
```

---

## 2. Gestión y Aislamiento de Perfiles de Niños (Párvulos)

Cada niño está estrictamente asociado al padre autenticado. Las rutas individuales implementan el middleware `child.owner` (`EnsureChildBelongsToParent`) garantizando aislamiento multi-inquilino.

### 2.1 Listar Niños del Padre Autenticado
- **Método:** `GET`
- **Ruta:** `/api/children`
- **Autenticación:** `Bearer Token` (`auth:sanctum`)

#### Respuestas
- **200 OK** (Solo lista los niños creados por el padre autenticado)
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "name": "Mateo",
      "birth_date": "2022-04-10",
      "avatar_key": "leon_leo",
      "reading_level": "vocales",
      "accessibility_settings": {
        "audio_feedback": true,
        "high_contrast": false,
        "voice_speed": "normal"
      },
      "created_at": "2026-11-15T19:40:00Z",
      "updated_at": "2026-11-15T19:40:00Z"
    }
  ]
}
```
- **401 Unauthorized**
```json
{
  "message": "Unauthenticated."
}
```

---

### 2.2 Crear Perfil de Niño
- **Método:** `POST`
- **Ruta:** `/api/children`
- **Autenticación:** `Bearer Token` (`auth:sanctum`)

#### Request Body
```json
{
  "name": "Mateo",
  "birth_date": "2022-04-10",
  "avatar_key": "leon_leo",
  "reading_level": "vocales",
  "accessibility_settings": {
    "audio_feedback": true,
    "high_contrast": false,
    "voice_speed": "normal"
  }
}
```

#### Respuestas
- **201 Created**
```json
{
  "message": "Perfil de párvulo creado con éxito.",
  "data": {
    "id": 1,
    "user_id": 1,
    "name": "Mateo",
    "birth_date": "2022-04-10",
    "avatar_key": "leon_leo",
    "reading_level": "vocales",
    "accessibility_settings": {
      "audio_feedback": true,
      "high_contrast": false,
      "voice_speed": "normal"
    },
    "created_at": "2026-11-15T19:40:00Z",
    "updated_at": "2026-11-15T19:40:00Z"
  }
}
```
- **401 Unauthorized**
```json
{
  "message": "Unauthenticated."
}
```
- **422 Unprocessable Content**
```json
{
  "message": "El nombre del niño o niña es obligatorio.",
  "errors": {
    "name": ["El nombre del niño o niña es obligatorio."]
  }
}
```

---

### 2.3 Obtener Detalle de un Perfil
- **Método:** `GET`
- **Ruta:** `/api/children/{child}`
- **Autenticación:** `Bearer Token` (`auth:sanctum`, `child.owner`)

#### Respuestas
- **200 OK**
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "name": "Mateo",
    "birth_date": "2022-04-10",
    "avatar_key": "leon_leo",
    "reading_level": "vocales",
    "accessibility_settings": {
      "audio_feedback": true,
      "high_contrast": false,
      "voice_speed": "normal"
    }
  }
}
```
- **401 Unauthorized** (Sin token o token inválido)
```json
{
  "message": "Unauthenticated."
}
```
- **403 Forbidden** (Si el padre autenticado intenta acceder al perfil de otro padre)
```json
{
  "message": "Acceso denegado: este perfil no pertenece al padre autenticado."
}
```

---

### 2.4 Actualizar Perfil de Niño
- **Método:** `PUT`
- **Ruta:** `/api/children/{child}`
- **Autenticación:** `Bearer Token` (`auth:sanctum`, `child.owner`)

#### Request Body
```json
{
  "name": "Mateo González",
  "avatar_key": "tigre_toño"
}
```

#### Respuestas
- **200 OK**
```json
{
  "message": "Perfil de párvulo actualizado con éxito.",
  "data": {
    "id": 1,
    "name": "Mateo González",
    "avatar_key": "tigre_toño"
  }
}
```
- **403 Forbidden** (Si el ID pertenece al hijo de otro padre)

---

### 2.5 Eliminar Perfil de Niño
- **Método:** `DELETE`
- **Ruta:** `/api/children/{child}`
- **Autenticación:** `Bearer Token` (`auth:sanctum`, `child.owner`)

#### Respuestas
- **200 OK**
```json
{
  "message": "Perfil de párvulo eliminado con éxito."
}
```
- **403 Forbidden** (Si el ID pertenece al hijo de otro padre)

---

## 3. Sincronización Offline-First de Progreso (`/api/sync/progress`)

Endpoint de sincronización masiva que procesa lotes de eventos generados sin conexión en dispositivos móviles o web, aplicando resolución de conflictos **Last-Write-Wins (LWW)** y soporte para **Soft Deletes**.

### 3.1 Sincronizar Lote de Eventos de Progreso
- **Método:** `POST`
- **Ruta:** `/api/sync/progress`
- **Autenticación:** `Bearer Token` (`auth:sanctum`)

#### Request Body
```json
{
  "events": [
    {
      "child_id": 1,
      "activity_id": "VOCAL_A_TRAZO",
      "score": 100,
      "stars": 3,
      "metadata": {
        "intentos": 1,
        "dispositivo": "Tablet SM-T290"
      },
      "updated_at": "2026-11-15T19:50:00.000Z",
      "deleted_at": null
    },
    {
      "child_id": 1,
      "activity_id": "FONEMA_M_PRACTICA",
      "score": 80,
      "stars": 2,
      "updated_at": "2026-11-15T19:55:00.000Z",
      "deleted_at": null
    }
  ]
}
```

#### Respuestas
- **200 OK** (Lote procesado exitosamente dentro de `DB::transaction`)
```json
{
  "message": "Lote de progreso sincronizado exitosamente.",
  "summary": {
    "total_events": 2,
    "inserted": 2,
    "updated": 0,
    "deleted": 0,
    "ignored": 0
  }
}
```
- **401 Unauthorized** (Sin token o token inválido)
```json
{
  "message": "Unauthenticated."
}
```
- **403 Forbidden** (Si algún `child_id` del lote no pertenece al padre autenticado)
```json
{
  "message": "Acceso denegado: el perfil infantil con ID 2 no pertenece al usuario autenticado."
}
```
- **422 Unprocessable Content** (Array vacío o campos requeridos ausentes)
```json
{
  "message": "El lote de eventos de progreso es obligatorio.",
  "errors": {
    "events": ["El lote de eventos de progreso es obligatorio."]
  }
}
```

---

## 4. Matriz de Códigos de Estado HTTP

| Código | Significado | Escenario |
| :--- | :--- | :--- |
| **200 OK** | Éxito | Lectura, actualización o eliminación completada. |
| **201 Created** | Creado | Registro de padre o creación de perfil de niño. |
| **401 Unauthorized** | No autenticado | Token ausente, revocado o credenciales de login incorrectas. |
| **403 Forbidden** | Acceso denegado | Un padre intenta consultar, editar o borrar el hijo de otro padre. |
| **404 Not Found** | No encontrado | El recurso solicitado no existe en la base de datos. |
| **422 Unprocessable Content** | Validación fallida | Faltan campos requeridos o no cumplen reglas (email inválido, password corto). |
