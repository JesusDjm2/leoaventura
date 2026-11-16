#!/usr/bin/env bash
# =============================================================================
# normalize_audio.sh — Pipeline de producción de audio de LeoPárvulos
#
# Normaliza grabaciones a -16 LUFS (EBU R128: medición + ganancia lineal exacta) y genera
# dos entregables por clip:
#   <out>/<categoria>/<nombre>.opus  (Opus 48 kHz mono, Android/Web)
#   <out>/<categoria>/<nombre>.m4a   (AAC-LC 48 kHz mono, iOS/Safari)
#
# Uso:
#   scripts/normalize_audio.sh [opciones] <entrada.wav> <categoria> [nombre]
#   scripts/normalize_audio.sh [opciones] --batch <dir_raw>
#
#   En modo --batch se espera <dir_raw>/<categoria>/<nombre>.{wav,flac,aif,aiff}
#
# Opciones:
#   -o, --out DIR     Raíz de salida (por defecto: assets/audio/v1)
#   --trim            Recorta silencios de inicio/fin (umbral: pico - 40 dB)
#   --lufs N          Loudness objetivo (por defecto: -16)
#   -h, --help        Ayuda
#
# Variables de entorno:
#   FFMPEG            Ruta al binario de ffmpeg (por defecto: ffmpeg del PATH)
#
# Categorías válidas: fonemas palabras instrucciones mascota
# Nombre: snake_case ASCII, prefijo según categoría (ver docs/audio/PIPELINE.md)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FFMPEG="${FFMPEG:-ffmpeg}"
OUT_ROOT="$REPO_ROOT/assets/audio/v1"
TARGET_I="-16"     # LUFS integrado
TARGET_TP="-1.5"   # dBTP (true peak): margen para el códec con pérdida

SAMPLE_RATE=48000
OPUS_BITRATE="48k" # voz mono: transparente a 48 kbps
AAC_BITRATE="64k"
TRIM=0

CATEGORIES=(fonemas palabras instrucciones mascota)
declare -A PREFIX=(
  [fonemas]="fonema"
  [palabras]="palabra"
  [instrucciones]="instruccion"
  [mascota]="mascota"
)

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*" >&2; }

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

is_category() {
  local c
  for c in "${CATEGORIES[@]}"; do [[ "$c" == "$1" ]] && return 0; done
  return 1
}

validate_name() {
  local category="$1" name="$2" prefix="${PREFIX[$1]}"
  [[ "$name" =~ ^[a-z0-9]+(_[a-z0-9]+)*$ ]] \
    || die "nombre inválido '$name': usa snake_case ASCII en minúsculas (sin tildes ni ñ)"
  [[ "$name" == "${prefix}_"* ]] \
    || die "nombre '$name' debe empezar por '${prefix}_' en la categoría '$category'"
}

# Imprime "<loudness integrado LUFS> <true peak dBFS>" de un archivo.
# apad solo afecta a clips < 0.4 s (el bloque mínimo de R128 es de 400 ms).
measure_r128() {
  local out
  out="$("$FFMPEG" -hide_banner -nostats -i "$1" -ac 1 \
    -af "apad=whole_dur=0.4,ebur128=peak=true:framelog=quiet" -f null - 2>&1)" \
    || die "ffmpeg falló midiendo $1"
  echo "$(awk '/Integrated loudness:/{getline; print $2}' <<<"$out" | tail -1)" \
       "$(awk '/True peak:/{getline; print $2}' <<<"$out" | tail -1)"
}

process_clip() {
  local input="$1" category="$2" name="$3"
  [[ -f "$input" ]] || die "no existe la entrada: $input"
  is_category "$category" || die "categoría inválida '$category' (válidas: ${CATEGORIES[*]})"
  validate_name "$category" "$name"

  local outdir="$OUT_ROOT/$category"
  mkdir -p "$outdir"

  # Archivo de trabajo: la entrada tal cual, o recortada si se pidió --trim.
  local src="$input" tmp=""
  if [[ $TRIM -eq 1 ]]; then
    # Umbral RELATIVO al pico de la toma (pico - 40 dB): un umbral fijo
    # borraría por completo una toma grabada baja. Se recorta ANTES de medir:
    # en clips cortos el silencio sobrante diluye la medición R128 (bloques de
    # 400 ms) y el resultado final quedaría 1-2 LU por encima del objetivo.
    local peak thr
    read -r _ peak < <(measure_r128 "$input")
    thr="$(awk -v p="$peak" 'BEGIN{t = p - 40; if (t < -80) t = -80; printf "%.1f", t}')"
    tmp="$(mktemp "${TMPDIR:-/tmp}/leo_audio_XXXXXX")"
    local sr="silenceremove=start_periods=1:start_threshold=${thr}dB:start_silence=0.05"
    "$FFMPEG" -hide_banner -loglevel error -y -i "$input" -ac 1 \
      -af "${sr},areverse,${sr},areverse" -c:a pcm_f32le -f wav "$tmp" \
      || die "ffmpeg falló recortando silencios"
    src="$tmp"
  fi

  # Pasada 1: loudness integrado y true peak (EBU R128) del clip final.
  # No se usa loudnorm para aplicar la ganancia: con entradas < 3 s (todos los
  # fonemas) loudnorm cae a modo dinámico y no llega al objetivo.
  local mi mtp
  read -r mi mtp < <(measure_r128 "$src")
  if [[ -z "$mi" || "$mi" == "-inf" ]] || awk -v i="$mi" 'BEGIN{exit !(i <= -69)}'; then
    [[ -n "$tmp" ]] && rm -f "$tmp"
    die "no se pudo medir loudness de $input (¿silencio?)"
  fi

  # Pasada 2: ganancia lineal exacta; limitador solo si el pico resultante
  # superaría el techo de true peak.
  local gain peak_after filter
  gain="$(awk -v t="$TARGET_I" -v i="$mi" 'BEGIN{printf "%.2f", t - i}')"
  peak_after="$(awk -v p="$mtp" -v g="$gain" 'BEGIN{printf "%.2f", p + g}')"
  filter="volume=${gain}dB:precision=double"
  if awk -v p="$peak_after" -v tp="$TARGET_TP" 'BEGIN{exit !(p > tp)}'; then
    local limit
    limit="$(awk -v tp="$TARGET_TP" 'BEGIN{printf "%.4f", 10^(tp/20)}')"
    filter+=",alimiter=limit=${limit}:attack=1:release=50:level=false"
    info "aviso: $name tendría pico de ${peak_after} dBFS; se aplica limitador a ${TARGET_TP} dB"
  fi
  filter+=",aresample=${SAMPLE_RATE}"

  # -map_metadata -1 / -fflags +bitexact: salida reproducible (mismo hash
  # para la misma entrada), clave para el manifiesto SHA-256.
  "$FFMPEG" -hide_banner -loglevel error -y -i "$src" -ac 1 -af "$filter" \
    -map_metadata -1 -fflags +bitexact -flags:a +bitexact \
    -c:a libopus -b:a "$OPUS_BITRATE" -application voip \
    "$outdir/$name.opus" || die "ffmpeg falló codificando Opus"

  "$FFMPEG" -hide_banner -loglevel error -y -i "$src" -ac 1 -af "$filter" \
    -map_metadata -1 -fflags +bitexact -flags:a +bitexact \
    -c:a aac -b:a "$AAC_BITRATE" -movflags +faststart \
    "$outdir/$name.m4a" || die "ffmpeg falló codificando AAC"

  [[ -n "$tmp" ]] && rm -f "$tmp"

  info "$category/$name  (entrada ${mi} LUFS → ${TARGET_I} LUFS)  → $name.opus, $name.m4a"
}

# ---------------------------------------------------------------------------
POSITIONAL=()
BATCH_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)   OUT_ROOT="$2"; shift 2 ;;
    --trim)     TRIM=1; shift ;;
    --lufs)     TARGET_I="$2"; shift 2 ;;
    --batch)    BATCH_DIR="$2"; shift 2 ;;
    -h|--help)  usage 0 ;;
    -*)         die "opción desconocida: $1" ;;
    *)          POSITIONAL+=("$1"); shift ;;
  esac
done

command -v "$FFMPEG" >/dev/null 2>&1 || [[ -x "$FFMPEG" ]] \
  || die "ffmpeg no encontrado. Instálalo o define FFMPEG=/ruta/a/ffmpeg"
"$FFMPEG" -hide_banner -encoders 2>/dev/null | grep -q libopus \
  || die "este ffmpeg no incluye libopus"

if [[ -n "$BATCH_DIR" ]]; then
  [[ -d "$BATCH_DIR" ]] || die "no existe el directorio: $BATCH_DIR"
  count=0
  shopt -s nullglob nocaseglob
  for category in "${CATEGORIES[@]}"; do
    for f in "$BATCH_DIR/$category"/*.{wav,flac,aif,aiff}; do
      base="$(basename "$f")"
      process_clip "$f" "$category" "${base%.*}"
      count=$((count + 1))
    done
  done
  info "lote terminado: $count clip(s) en $OUT_ROOT"
  exit 0
fi

[[ ${#POSITIONAL[@]} -ge 2 ]] || usage 1
input="${POSITIONAL[0]}"
category="${POSITIONAL[1]}"
name="${POSITIONAL[2]:-$(basename "${input%.*}")}"
process_clip "$input" "$category" "$name"
