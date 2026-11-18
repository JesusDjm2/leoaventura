#!/usr/bin/env bash
# Simula el cliente móvil consultando GET /api/progress con el token del padre
# para verificar sincronización multi-dispositivo Web -> Backend Laravel -> Móvil.
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000}"
PARENT_EMAIL="${1:?Uso: $0 <email_padre> <password_padre> [expected_activity_id]}"
PARENT_PASSWORD="${2:?Uso: $0 <email_padre> <password_padre> [expected_activity_id]}"
EXPECTED_ACTIVITY="${3:-act_m_tracing}"

echo "[Mobile-Sim] 1. Iniciando sesión móvil en ${API_BASE}/api/login..."
LOGIN_JSON=$(curl -sS -X POST "${API_BASE}/api/login" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"email\":\"${PARENT_EMAIL}\",\"password\":\"${PARENT_PASSWORD}\"}")

TOKEN=$(node -e "const d = JSON.parse(process.argv[1]); console.log(d.data?.token || d.token || d.access_token || '');" "$LOGIN_JSON")
if [ -z "$TOKEN" ]; then
  echo "[Mobile-Sim] ❌ No se obtuvo token Sanctum en login." >&2
  exit 1
fi
echo "[Mobile-Sim] ✅ Token Sanctum obtenido correctamente."

echo "[Mobile-Sim] 2. Consultando GET ${API_BASE}/api/progress..."
PROGRESS_JSON=$(curl -sS -X GET "${API_BASE}/api/progress" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${TOKEN}")

node -e "
const data = JSON.parse(process.argv[1]);
const expected = process.argv[2];
const match = (data.progress || []).find(p => p.activity_id === expected);
if (!match) {
  console.error('[Mobile-Sim] ❌ No se encontró la actividad', expected, 'en /api/progress:', JSON.stringify(data));
  process.exit(1);
}
console.log('[Mobile-Sim] ✅ Progreso sincronizado confirmado por la API:');
console.log(JSON.stringify({
  total_completed: data.total_completed,
  total_stars: data.total_stars,
  synced_record: match
}, null, 2));
" "$PROGRESS_JSON" "$EXPECTED_ACTIVITY"
