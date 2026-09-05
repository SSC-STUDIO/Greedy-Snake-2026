#!/usr/bin/env python3
"""2x upsample Level01 far/mid parallax strips (not nearest-only).

Mountains / graveyard: Scale2x (EPX) so hard pixel edges stay stairstep-clean.
Sky: Lanczos 2x + a short unsharp pass — the moon/clouds are painted ramps,
so Scale2x would collapse to nearest and look identical at the same composition.

Outputs:
  assets/env/parallax_sky_2x.png
  assets/env/parallax_mountains_2x.png
  assets/env/parallax_graveyard_2x.png

Usage (from repo root):
  python tools/upsample_parallax.py
"""
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ENV = ROOT / "assets" / "env"

# Authored 1x strips currently referenced by Level01_Static.tscn.
JOBS = (
    ("parallax_sky.png", "parallax_sky_2x.png", "sharpen"),
    ("parallax_mountains.png", "parallax_mountains_2x.png", "scale2x"),
    ("parallax_graveyard.png", "parallax_graveyard_2x.png", "scale2x"),
)


def scale2x(src: Image.Image) -> Image.Image:
    """EPX / Scale2x. New edge texels; flat runs stay as 2x2 clones of the source."""
    src = src.convert("RGBA")
    w, h = src.size
    px = src.load()
    out = Image.new("RGBA", (w * 2, h * 2))
    dst = out.load()

    def at(x: int, y: int):
        if x < 0:
            x = 0
        elif x >= w:
            x = w - 1
        if y < 0:
            y = 0
        elif y >= h:
            y = h - 1
        return px[x, y]

    for y in range(h):
        for x in range(w):
            b = at(x, y - 1)
            d = at(x - 1, y)
            e = at(x, y)
            f = at(x + 1, y)
            hpix = at(x, y + 1)
            if b != hpix and d != f:
                e0 = d if d == b else e
                e1 = b if b == f else e
                e2 = d if d == hpix else e
                e3 = hpix if hpix == f else e
            else:
                e0 = e1 = e2 = e3 = e
            ox, oy = x * 2, y * 2
            dst[ox, oy] = e0
            dst[ox + 1, oy] = e1
            dst[ox, oy + 1] = e2
            dst[ox + 1, oy + 1] = e3
    return out


def sharpen_2x(src: Image.Image) -> Image.Image:
    """Limited sharpening 2x for painted strips. Not a photo/waifu pass."""
    rgba = src.convert("RGBA")
    big = rgba.resize((rgba.size[0] * 2, rgba.size[1] * 2), Image.Resampling.LANCZOS)
    return big.filter(ImageFilter.UnsharpMask(radius=1.1, percent=145, threshold=3))


def upsample(src: Image.Image, kind: str) -> Image.Image:
    if kind == "scale2x":
        return scale2x(src)
    if kind == "sharpen":
        return sharpen_2x(src)
    raise ValueError(f"unknown upsample kind: {kind}")


def main() -> None:
    for src_name, dst_name, kind in JOBS:
        src_path = ENV / src_name
        dst_path = ENV / dst_name
        src = Image.open(src_path)
        out = upsample(src, kind)
        if out.size != (src.size[0] * 2, src.size[1] * 2):
            raise SystemExit(f"{src_name}: expected 2x size, got {out.size}")
        out.save(dst_path, "PNG")
        print(f"{src_name} {src.size} {src.mode} -> {dst_name} {out.size} ({kind})")


if __name__ == "__main__":
    main()
