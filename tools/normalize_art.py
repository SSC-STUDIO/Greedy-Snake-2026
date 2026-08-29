#!/usr/bin/env python3
"""normalize_art.py — process ImageGen outputs into game-ready transparent PNGs.

ImageGen's `background: "transparent"` is not reliable — the platform often
returns RGB with a flat gray background instead. This tool handles both:

  RGBA path: trust alpha, mask the bottom-right watermark corner, bbox on alpha.
  RGB path:  sample corner pixels to recover the background color, then key out
             pixels close to that color (with tolerance), then bbox on a
             reconstructed alpha.

Pipeline:
  1. Open source; if RGB, run auto-key to recover RGBA.
  2. If watermark cropping on, zero alpha in the bottom-right corner
     (ImageGen adds "AI生成 WORKBUDDY" in the bottom-right).
  3. Find the tight content bbox.
  4. Crop to bbox.
  5. Scale to target height (preserving aspect, LANCZOS for downscale).
  6. Output: feet at bottom edge, content scaled to target height.

Usage:
  python tools/normalize_art.py -i .ai_gen/foo.png -o assets/.../idle.png -H 96
"""
import argparse
import sys
from pathlib import Path
from PIL import Image


def find_content_bbox(img: Image.Image, alpha_min: int):
    """Return (x0, y0, x1, y1) of the tight content bbox."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.split()[-1]
    bbox = alpha.point(lambda a: 255 if a > alpha_min else 0).getbbox()
    return bbox


def mask_watermark(img: Image.Image, w_frac: float, h_frac: float) -> None:
    """Zero alpha in the bottom-right watermark region (in place)."""
    w, h = img.size
    x0 = int(w * (1.0 - w_frac))
    y0 = int(h * (1.0 - h_frac))
    pixels = img.load()
    for y in range(y0, h):
        for x in range(x0, w):
            r, g, b, a = pixels[x, y]
            if a > 0:
                pixels[x, y] = (r, g, b, 0)


def sample_bg_color(img: Image.Image) -> tuple[int, int, int]:
    """Robust background color: median of 4 corner patches."""
    w, h = img.size
    rs, gs, bs = [], [], []
    s = max(2, min(w, h) // 30)
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    for cx, cy in corners:
        for dy in range(-s, s + 1):
            for dx in range(-s, s + 1):
                x = max(0, min(w - 1, cx + dx))
                y = max(0, min(h - 1, cy + dy))
                p = img.getpixel((x, y))
                rs.append(p[0]); gs.append(p[1]); bs.append(p[2])
    rs.sort(); gs.sort(); bs.sort()
    mid = len(rs) // 2
    return (rs[mid], gs[mid], bs[mid])


def auto_key_to_rgba(img: Image.Image, tolerance: int) -> Image.Image:
    """Sample bg color and key out pixels within tolerance. Returns RGBA."""
    bg = sample_bg_color(img)
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    br, bgb, bb = bg
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if (abs(r - br) <= tolerance
                    and abs(g - bgb) <= tolerance
                    and abs(b - bb) <= tolerance):
                pixels[x, y] = (r, g, b, 0)
    return rgba


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("-i", "--input", required=True, help="source PNG")
    ap.add_argument("-o", "--output", required=True, help="destination PNG")
    ap.add_argument("-H", "--height", type=int, default=96, help="target render height (px)")
    ap.add_argument("--alpha-min", type=int, default=8, help="alpha threshold for content detection")
    ap.add_argument("--watermark-w", type=float, default=0.22, help="watermark crop width fraction (right)")
    ap.add_argument("--watermark-h", type=float, default=0.15, help="watermark crop height fraction (bottom)")
    ap.add_argument("--no-watermark", action="store_true", help="skip watermark masking")
    ap.add_argument("--key-tolerance", type=int, default=12, help="RGB auto-key tolerance per channel")
    ap.add_argument("--print-bg", action="store_true", help="print detected bg color and exit")
    args = ap.parse_args()

    src = Path(args.input)
    out = Path(args.output)
    if not src.is_file():
        print(f"ERR: input not found: {src}", file=sys.stderr)
        return 1

    img = Image.open(src)
    bg = None

    if img.mode == "RGB":
        bg = sample_bg_color(img)
        if args.print_bg:
            print(f"bg color: {bg}")
            return 0
        img = auto_key_to_rgba(img, args.key_tolerance)
        if not args.no_watermark:
            mask_watermark(img, args.watermark_w, args.watermark_h)
    else:
        if img.mode != "RGBA":
            img = img.convert("RGBA")
        if not args.no_watermark:
            mask_watermark(img, args.watermark_w, args.watermark_h)

    bbox = find_content_bbox(img, args.alpha_min)
    if bbox is None:
        print(f"ERR: no content (alpha>{args.alpha_min}) in {src}", file=sys.stderr)
        return 2

    cropped = img.crop(bbox)
    cw, ch = cropped.size
    scale = args.height / ch
    new_w = max(1, round(cw * scale))
    scaled = cropped.resize((new_w, args.height), Image.Resampling.LANCZOS)

    out.parent.mkdir(parents=True, exist_ok=True)
    scaled.save(out, format="PNG", optimize=True)
    bg_info = f"  bg={bg}" if bg is not None else ""
    print(f"normalize: {src.name} -> {out.name}  bbox={bbox}  size={scaled.size[0]}x{scaled.size[1]}{bg_info}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
