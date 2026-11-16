#!/usr/bin/env bash
# Copia el catálogo publicado (assets/audio/v<N>/) a client/assets/audio/v<N>/
# para empaquetarlo en la app. Ejecutar después de `php artisan audio:manifest`.
#
# Uso: scripts/bundle_flutter_audio.sh [version]   (por defecto: 1)
#
# La app reproduce desde el asset solo si su SHA-256 coincide con el del
# manifiesto del servidor; si el servidor tiene una versión más nueva de un
# clip, la descarga a caché. Ver docs/audio/AUDIO_SERVICE.md.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V="${1:-1}"
SRC="$REPO_ROOT/assets/audio/v$V"
DST="$REPO_ROOT/client/assets/audio/v$V"

[[ -f "$SRC/manifest.json" ]] || { echo "ERROR: falta $SRC/manifest.json (ejecuta php artisan audio:manifest)" >&2; exit 1; }

rm -rf "$DST"
mkdir -p "$DST"
for cat in fonemas palabras instrucciones mascota; do
  mkdir -p "$DST/$cat"
  cp "$SRC/$cat/".gitkeep "$DST/$cat/" 2>/dev/null || touch "$DST/$cat/.gitkeep"
  shopt -s nullglob
  for f in "$SRC/$cat"/*.opus "$SRC/$cat"/*.m4a; do cp "$f" "$DST/$cat/"; done
  shopt -u nullglob
done
cp "$SRC/manifest.json" "$DST/manifest.json"
echo "Empaquetado v$V: $(find "$DST" -name '*.opus' | wc -l) clips opus, $(find "$DST" -name '*.m4a' | wc -l) aac → $DST"
