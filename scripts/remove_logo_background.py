"""Quita el fondo liso del logo y lo exporta como PNG transparente recortado.

Uso:
    python -I scripts/remove_logo_background.py <entrada.jpg> <salida.png> [--max-width 1600]

Método:
  1. Color de fondo = mediana de los píxeles del borde.
  2. Región de fondo = píxeles parecidos al fondo CONECTADOS al borde (flood fill),
     para no borrar azules internos del logo (letras "URA", libro, destellos).
     Los huecos cerrados se quitan solo si son casi idénticos al fondo y grandes.
  3. Alfa suave en el contorno según la distancia de color, y "decontaminación":
     se resta el celeste que el antialiasing mezcló en los bordes.
  4. Recorte al contenido con margen.
"""
import argparse
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

T_FLOOD = 38.0   # distancia RGB máx. para considerar un píxel "fondo" en el flood fill
T_IN = 14.0      # por debajo: totalmente transparente
T_OUT = 70.0     # por encima: totalmente opaco
T_HOLE = 16.0    # huecos cerrados: solo si son casi idénticos al fondo
MIN_HOLE = 400   # px mínimos para considerar un hueco cerrado como fondo


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--max-width", type=int, default=0)
    ap.add_argument("--margin", type=int, default=24)
    a = ap.parse_args()

    img = Image.open(a.src).convert("RGB")
    rgb = np.asarray(img).astype(np.float32)
    h, w, _ = rgb.shape

    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    print(f"fondo: #{int(bg[0]):02X}{int(bg[1]):02X}{int(bg[2]):02X}", file=sys.stderr)

    # Flood fill desde todo el borde sobre la máscara de candidatos.
    cand = Image.fromarray(((dist < T_FLOOD) * 255).astype(np.uint8), "L")
    seeds = [(x, 0) for x in range(0, w, 8)] + [(x, h - 1) for x in range(0, w, 8)] \
        + [(0, y) for y in range(0, h, 8)] + [(w - 1, y) for y in range(0, h, 8)]
    for s in seeds:
        if cand.getpixel(s) == 255:
            ImageDraw.floodfill(cand, s, 128)
    region = np.asarray(cand) == 128

    # Huecos cerrados casi idénticos al fondo (p. ej. entre brazo y cuerpo).
    tight = Image.fromarray((((dist < T_HOLE) & ~region) * 255).astype(np.uint8), "L")
    arr = np.asarray(tight).copy()
    holes = 0
    ys, xs = np.nonzero(arr == 255)
    for y, x in zip(ys[::50], xs[::50]):
        if tight.getpixel((int(x), int(y))) != 255:
            continue
        ImageDraw.floodfill(tight, (int(x), int(y)), 77)
        comp = np.asarray(tight) == 77
        if comp.sum() >= MIN_HOLE:
            region |= comp
            holes += 1
        tight.paste(Image.fromarray(np.where(comp, 1, np.asarray(tight)).astype(np.uint8), "L"))
    print(f"huecos cerrados quitados: {holes}", file=sys.stderr)

    # Banda de contorno = región de fondo dilatada 3 px.
    band = np.asarray(Image.fromarray((region * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))) > 0
    soft = np.clip((dist - T_IN) / (T_OUT - T_IN), 0.0, 1.0)
    alpha = np.where(band, soft, 1.0)
    alpha = np.where(region & (dist < T_IN), 0.0, alpha)

    # Decontaminación: C = (C_obs - (1 - a) * bg) / a
    a3 = alpha[..., None]
    with np.errstate(divide="ignore", invalid="ignore"):
        clean = np.where(a3 > 0.02, (rgb - (1.0 - a3) * bg) / np.maximum(a3, 1e-3), rgb)
    clean = np.clip(clean, 0, 255)

    out = np.dstack([clean, alpha * 255.0]).round().astype(np.uint8)
    rgba = Image.fromarray(out, "RGBA")

    # Recorte al contenido visible (alfa > 8) con margen.
    ys, xs = np.nonzero(out[..., 3] > 8)
    m = a.margin
    box = (max(xs.min() - m, 0), max(ys.min() - m, 0), min(xs.max() + m + 1, w), min(ys.max() + m + 1, h))
    rgba = rgba.crop(box)
    if a.max_width and rgba.width > a.max_width:
        rgba = rgba.resize((a.max_width, round(rgba.height * a.max_width / rgba.width)), Image.LANCZOS)
    rgba.save(a.dst, optimize=True)
    print(f"guardado {a.dst} ({rgba.width}x{rgba.height})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
