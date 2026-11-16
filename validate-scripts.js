import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const filePath = path.join(__dirname, 'docs', 'audio', 'mascot_scripts.md');

if (!fs.existsSync(filePath)) {
  console.error(`❌ Archivo no encontrado: ${filePath}`);
  process.exit(1);
}

const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split('\n');

const technicalJargon = [
  'api', 'token', 'cache', 'sqlite', 'database', 'servidor', 'http',
  'json', 'payload', 'código', 'error', 'excepción', 'bug', 'crash',
  'login', 'register', 'auth', 'endpoint', 'red', 'driver'
];

const requiredContexts = new Set(['onboarding', 'instrucciones', 'exito', 'error', 'transiciones']);
const foundContexts = new Set();

let validCount = 0;
let errors = [];

for (const line of lines) {
  const trimmed = line.trim();
  if (!trimmed.startsWith('|') || trimmed.includes('| ID |') || trimmed.includes('| :---')) {
    continue;
  }

  const parts = trimmed.split('|').map(p => p.trim()).filter(Boolean);
  if (parts.length < 4) continue;

  const [id, text, tone, context] = parts;

  // Contar palabras limpiando signos de puntuación
  const words = text.replace(/[¡!¿?.,:;"']/g, '').split(/\s+/).filter(w => w.length > 0);
  const wordCount = words.length;

  if (wordCount > 7) {
    errors.push(`ID [${id}] excede 7 palabras (${wordCount}): "${text}"`);
  }

  // Verificar jerga técnica
  for (const word of words) {
    const lower = word.toLowerCase();
    if (technicalJargon.includes(lower)) {
      errors.push(`ID [${id}] contiene jerga técnica prohibida ("${word}")`);
    }
  }

  foundContexts.add(context.toLowerCase());
  validCount++;
}

// Validar cobertura de los 5 contextos
for (const req of requiredContexts) {
  if (!foundContexts.has(req)) {
    errors.push(`Falta cubrir el contexto requerido: "${req}"`);
  }
}

if (errors.length > 0) {
  console.error('❌ Errores en guiones:');
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

if (validCount < 20) {
  console.error(`❌ Se esperaban al menos 20 guiones, se encontraron ${validCount}`);
  process.exit(1);
}

// Mensaje exacto requerido por la stopping rule
console.log('✅ 20 guiones válidos');
