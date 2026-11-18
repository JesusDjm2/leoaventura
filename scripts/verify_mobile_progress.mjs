/**
 * Simula la app móvil autenticándose en Laravel y consultando GET /api/progress
 * para verificar que el progreso guardado desde la web ya existe en el servidor.
 *
 * Uso: node scripts/verify_mobile_progress.mjs <email> <password> [expected_activity_id]
 */
const apiBase = process.env.API_BASE ?? 'http://127.0.0.1:8000';
const [, , email, password, expectedActivity = 'act_m_tracing'] = process.argv;

if (!email || !password) {
  console.error('Uso: node scripts/verify_mobile_progress.mjs <email> <password> [expected_activity_id]');
  process.exit(1);
}

console.log(`[Mobile-Sim] 1. POST ${apiBase}/api/login (dispositivo móvil)`);
const loginRes = await fetch(`${apiBase}/api/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
  body: JSON.stringify({ email, password }),
});

if (!loginRes.ok) {
  console.error(`[Mobile-Sim] ❌ Login fallido (${loginRes.status}):`, await loginRes.text());
  process.exit(1);
}

const loginBody = await loginRes.json();
const token = loginBody?.data?.token ?? loginBody?.token ?? loginBody?.access_token;
if (!token) {
  console.error('[Mobile-Sim] ❌ No se recibió token Sanctum.');
  process.exit(1);
}
console.log('[Mobile-Sim] ✅ Token Sanctum recibido correctamente.');

console.log(`[Mobile-Sim] 2. GET ${apiBase}/api/progress con Bearer token`);
const progressRes = await fetch(`${apiBase}/api/progress`, {
  method: 'GET',
  headers: { Accept: 'application/json', Authorization: `Bearer ${token}` },
});

if (!progressRes.ok) {
  console.error(`[Mobile-Sim] ❌ Error en GET /api/progress (${progressRes.status}):`, await progressRes.text());
  process.exit(1);
}

const progressBody = await progressRes.json();
const synced = (progressBody.progress ?? []).find((p) => p.activity_id === expectedActivity);

if (!synced) {
  console.error(`[Mobile-Sim] ❌ Actividad "${expectedActivity}" no encontrada en GET /api/progress:`, progressBody);
  process.exit(1);
}

console.log('[Mobile-Sim] ✅ Sincronización multi-dispositivo verificada por GET /api/progress:');
console.log(
  JSON.stringify(
    {
      total_completed: progressBody.total_completed,
      total_stars: progressBody.total_stars,
      child_name: synced.child_name,
      activity_id: synced.activity_id,
      score: synced.score,
      stars: synced.stars,
      updated_at: synced.updated_at,
    },
    null,
    2
  )
);
