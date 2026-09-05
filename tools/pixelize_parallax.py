#!/usr/bin/env python3
"""AI redraw -> hard-edge pixel strips for Level01's 5 parallax plates.

Shared crunch (every layer):
  crop to an integer multiple of the game size
  BOX downsample by the same factor
  contrast bump
  16-color adaptive quantize, no dither
  silhouette plates: key only ABOVE the ridge, then seal holes / belly

Usage (from repo root):
  python tools/pixelize_parallax.py
  python tools/pixelize_parallax.py --preview
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
AI = ROOT / "assets" / "external" / "ai"
ENV = ROOT / "assets" / "env"
PREVIEW = ROOT / "screenshots"

# One crunch for every plate: BOX/2 + 16 colors. 1 world unit = 1 texel.
COLORS = 16
BOX = 2
SKY_MAX = 12

JOBS = (
    {
        "name": "Far / sky",
        "src": "parallax_sky_ai.png",
        "dst": "parallax_sky_px.png",
        "crop": (64, 32, 1408, 896),
        "key_sky": False,
        "seal": "",
        "scrub_warm": True,
        "heal_moon": True,
        # Editor fallback. Play uses SkyPlate (2048, wrap-safe). Do not wrap-crop this plate.
    },
    {
        "name": "FarMountains",
        "src": "parallax_far_mountains_ai.png",
        "dst": "parallax_far_mountains_px.png",
        "crop": (0, 448, 1536, 304),
        "key_sky": True,
        "seal": "full",
        "scrub_warm": True,
    },
    {
        "name": "Mid / mountains",
        "src": "parallax_mountains_ai.png",
        "dst": "parallax_mountains_px.png",
        "crop": (384, 80, 768, 716),
        "key_sky": True,
        "seal": "full",
        "scrub_warm": False,
    },
    {
        "name": "MidGrove",
        "src": "parallax_mid_grove_ai.png",
        "dst": "parallax_mid_grove_px.png",
        "crop": (0, 576, 1536, 384),
        "key_sky": "all",
        "key_thr": 48,
        "seal": "feet",
        "punch_fill": True,
        "scrub_warm": True,
    },
    {
        "name": "Hills / graveyard",
        "src": "parallax_graveyard_ai.png",
        "dst": "parallax_graveyard_px.png",
        "crop": (0, 280, 1536, 492),
        "key_sky": True,
        "seal": "full",
        "scrub_warm": True,
    },
    {
        "name": "CloudFar",
        "src": "parallax_clouds_ai.png",
        "dst": "parallax_clouds_px.png",
        "crop": (0, 176, 1536, 400),
        "key_sky": "all",
        "seal": "",
        "scrub_warm": True,
        "wrap": 24,
        "colors": 12,
        "key_thr": 14,
    },
    {
        "name": "CloudLow",
        "src": "parallax_clouds_ai.png",
        "dst": "parallax_clouds_low_px.png",
        "crop": (0, 720, 1536, 128),
        "key_sky": "all",
        "seal": "",
        "scrub_warm": True,
        "wrap": 24,
        "colors": 12,
        "key_thr": 14,
    },
    {
        "name": "Fog",
        "src": "parallax_fog_ai.png",
        "dst": "parallax_fog_px.png",
        "crop": (0, 576, 1536, 160),
        "key_sky": "all",
        "seal": "",
        "scrub_warm": True,
        "wrap": 24,
        "colors": 8,
        "key_thr": 18,
    },
    {
        "name": "NearGround",
        "src": "parallax_near_ground_ai.png",
        "dst": "parallax_near_ground_px.png",
        "crop": (0, 576, 1280, 144),
        "key_sky": "all",
        "key_thr": 48,
        "seal": "feet",
        "punch_fill": True,
        "scrub_warm": True,
        "wrap": 16,
        "colors": 12,
        # Stones / dirt lip slide at motion 0.78. Keep grass + bushes only.
        "soft_only": "near",
    },
    {
        "name": "Foreground",
        "src": "parallax_foreground_ai.png",
        "dst": "parallax_foreground_px.png",
        "crop": (0, 592, 1280, 128),
        "key_sky": "all",
        "key_thr": 48,
        # No dirt pad: seal_feet + 8 colors turned grass into stone pillars.
        "seal": "",
        "punch_fill": True,
        "scrub_warm": True,
        "wrap": 16,
        "colors": 12,
        "soft_only": "fore",
    },
)


def is_sky_rgb(rgb: tuple[int, int, int], thr: int = SKY_MAX) -> bool:
    return max(rgb) < thr


def is_moon_rgb(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    return r > 150 and b > 70 and r >= g + 12


def is_warm(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    return r > 90 and r > b + 25 and g > 30 and b < 100


def crop_box(img: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = box
    return img.crop((x, y, x + w, y + h))


def box_down(img: Image.Image, factor: int) -> Image.Image:
    if factor < 2 or img.size[0] % factor or img.size[1] % factor:
        raise ValueError(f"BOX factor {factor} does not divide {img.size}")
    tw, th = img.size[0] // factor, img.size[1] // factor
    return img.resize((tw, th), Image.Resampling.BOX)


def crunch(img: Image.Image) -> Image.Image:
    """Same contrast pass on every plate so grain matches."""
    rgb = img.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(1.28)
    rgb = ImageEnhance.Color(rgb).enhance(0.92)
    if img.mode == "RGBA":
        out = rgb.convert("RGBA")
        out.putalpha(img.getchannel("A"))
        return out
    return rgb


def scrub_warm(img: Image.Image) -> Image.Image:
    """Remap orange/gold specks onto a nearby purple so the sky stays cool."""
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128 or not is_warm((r, g, b)):
                continue
            px[x, y] = (max(40, b + 20), max(8, g // 3), min(255, max(b, 70)), a)
    return out


def quantize_rgba(img: Image.Image, colors: int) -> Image.Image:
    rgba = img.convert("RGBA")
    rgb = Image.new("RGB", rgba.size)
    rgb.paste(rgba)
    pal = rgb.quantize(
        colors=colors,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE,
    )
    out = pal.convert("RGBA")
    src = rgba.load()
    dst = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = dst[x, y]
            a = src[x, y][3]
            if a < 128:
                dst[x, y] = (0, 0, 0, 0)
            else:
                dst[x, y] = (r, g, b, 255)
    return out


def key_above_silhouette(img: Image.Image) -> Image.Image:
    """Only the sky above the first ridge texel. Does not punch the belly."""
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    for x in range(w):
        for y in range(h):
            r, g, b, a = px[x, y]
            if a > 0 and not is_sky_rgb((r, g, b)):
                break
            px[x, y] = (0, 0, 0, 0)
    return out


def key_all_dark(img: Image.Image, thr: int = SKY_MAX) -> Image.Image:
    """Punch every near-black texel (sparse clouds / fog wisps)."""
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and is_sky_rgb((r, g, b), thr):
                px[x, y] = (0, 0, 0, 0)
    return out


def wrap_fade(src: Image.Image, band: int = 24) -> Image.Image:
    """Horizontal seam blend so a strip can mirror-tile.

    Hard-edge: per-texel lerp in a short overlap, then crop. No Gaussian.
    Play-time sky/clouds are generated by SkyPlate (GDScript) instead of
    tiling this short Far plate; wrap here is for authored cloud/fog strips.
    """
    w, h = src.size
    if band < 2 or w <= band:
        return src
    out_w = w - band
    out = src.crop((0, 0, out_w, h)).copy()
    po, ps = out.load(), src.load()
    for i in range(band):
        t = (i + 0.5) / band
        for y in range(h):
            a = ps[out_w + i, y]
            b = ps[i, y]
            po[i, y] = tuple(int(a[c] + (b[c] - a[c]) * t) for c in range(len(a)))
    return out


def modal_body(img: Image.Image) -> tuple[int, int, int]:
    px = img.load()
    w, h = img.size
    counts: dict[tuple[int, int, int], int] = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128 or is_sky_rgb((r, g, b)):
                continue
            key = (r, g, b)
            counts[key] = counts.get(key, 0) + 1
    if not counts:
        return (12, 6, 32)
    return max(counts, key=counts.get)


def _fill_from(px, x: int, y0: int, h: int, body: tuple[int, int, int]) -> None:
    for y in range(y0, h):
        r, g, b, a = px[x, y]
        if a < 128 or is_sky_rgb((r, g, b)):
            px[x, y] = (body[0], body[1], body[2], 255)


def seal_silhouette(img: Image.Image) -> Image.Image:
    """Fill holes between a column's first ridge and the floor (mountain wall)."""
    out = img.convert("RGBA")
    body = modal_body(out)
    px = out.load()
    w, h = out.size
    firsts: list[int] = []
    for x in range(w):
        first = -1
        for y in range(h):
            r, g, b, a = px[x, y]
            if a >= 128 and not is_sky_rgb((r, g, b)):
                first = y
                break
        firsts.append(first)
        if first >= 0:
            _fill_from(px, x, first, h, body)
    ridged = [f for f in firsts if f >= 0]
    if not ridged:
        return out
    ridged.sort()
    typical = ridged[int(len(ridged) * 0.65)]
    floor = min(h - 1, typical + max(8, h // 6))
    for x in range(w):
        if firsts[x] < 0:
            _fill_from(px, x, floor, h, body)
    return out


def seal_horizon(img: Image.Image, band_ratio: float = 0.28) -> Image.Image:
    """Sparse plates: only a low floor. Do not fill from branch-tips (boxy halos)."""
    out = img.convert("RGBA")
    body = modal_body(out)
    px = out.load()
    w, h = out.size
    y0 = int(h * (1.0 - band_ratio))
    for x in range(w):
        _fill_from(px, x, y0, h, body)
    return out


def seal_feet(img: Image.Image, pad: int = 10) -> Image.Image:
    """Pad a short dirt strip under each column's last solid pixel. Gaps stay empty."""
    out = img.convert("RGBA")
    body = modal_body(out)
    if max(body) < 40:
        body = (28, 18, 52)
    px = out.load()
    w, h = out.size
    for x in range(w):
        last = -1
        for y in range(h):
            r, g, b, a = px[x, y]
            if a >= 128 and not is_sky_rgb((r, g, b), 48):
                last = y
        if last < 0 or last >= h - 4:
            continue
        y1 = min(h, last + pad)
        for y in range(last + 1, y1):
            r, g, b, a = px[x, y]
            if a < 128 or is_sky_rgb((r, g, b), 48):
                px[x, y] = (body[0], body[1], body[2], 255)
    return out


def _row_frac(px, w: int, y: int) -> float:
    n = 0
    for x in range(w):
        if px[x, y][3] >= 128:
            n += 1
    return n / w if w else 0.0


def _column_tops(px, w: int, h: int) -> list[int]:
    tops: list[int] = []
    for x in range(w):
        top = -1
        for y in range(h):
            if px[x, y][3] >= 128:
                top = y
                break
        tops.append(top)
    return tops


def _stick_spans(
    tops: list[int], shelf: int, min_stick: int = 4
) -> list[tuple[int, int, int, float, float, int]]:
    """Return (x0, x1, max_stick, mean_stick, fill, top_jumps) above a dirt shelf."""
    w = len(tops)
    stick = [(shelf - t) if t >= 0 and t < shelf else 0 for t in tops]
    spans: list[tuple[int, int, int, float, float, int]] = []
    x = 0
    while x < w:
        if stick[x] < min_stick:
            x += 1
            continue
        x0 = x
        while x < w and stick[x] >= min_stick:
            x += 1
        x1 = x - 1
        chunk = stick[x0 : x1 + 1]
        max_h = max(chunk)
        mean_h = sum(chunk) / len(chunk)
        jumps = 0
        for xx in range(x0, x1):
            a = tops[xx] if tops[xx] >= 0 else shelf
            b = tops[xx + 1] if tops[xx + 1] >= 0 else shelf
            if abs(a - b) >= 2:
                jumps += 1
        spans.append((x0, x1, max_h, mean_h, 0.0, jumps))
    return spans


def _span_fill(px, tops: list[int], x0: int, x1: int, shelf: int, max_h: int) -> float:
    if max_h <= 0:
        return 0.0
    area = 0
    for x in range(x0, x1 + 1):
        t = tops[x]
        if t < 0:
            continue
        for y in range(t, shelf):
            if px[x, y][3] >= 128:
                area += 1
    box = (x1 - x0 + 1) * max_h
    return area / box if box else 0.0


def _keep_near_span(width: int, max_stick: int, fill: float, jumps: int) -> bool:
    """Bushes (wide) and grass (irregular / low fill). Drop monuments and rocks."""
    if width >= 32 and max_stick >= 14:
        return True
    if fill >= 0.75 and max_stick >= 14 and width >= 16:
        return False
    if fill >= 0.70 and jumps <= 2 and max_stick <= 10 and 8 <= width <= 16:
        return False
    if fill <= 0.70 and (jumps >= 3 or fill <= 0.58):
        return True
    if max_stick >= 8 and fill <= 0.66 and width <= 24:
        return True
    return False


def _keep_fore_clump(width: int, height: int, fill: float, jag: float) -> bool:
    """Edge grass stays. High-fill stone pillars / grave shards go."""
    if fill >= 0.60 and width <= 22 and height >= 16 and jag <= 10.5:
        return False
    return True


def _settle_to_bottom(img: Image.Image, margin: int = 4) -> None:
    """Slide remaining texels down so plant feet sit on the strip lip."""
    px = img.load()
    w, h = img.size
    last = -1
    for y in range(h - 1, -1, -1):
        for x in range(w):
            if px[x, y][3] >= 128:
                last = y
                break
        if last >= 0:
            break
    if last < 0:
        return
    dest = min(h - 1, max(last, h - max(1, margin)))
    dy = dest - last
    if dy <= 0:
        return
    for y in range(h - 1, -1, -1):
        src_y = y - dy
        for x in range(w):
            if src_y < 0:
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = px[x, src_y]


def strip_hard_soft_only(img: Image.Image, mode: str) -> Image.Image:
    """Key tombstones / rubble / dirt lips out of near-camera strips.

    Erases to transparent, never a black box. ``near`` keeps bush+grass columns
    and drops the sliding dirt shelf between them. ``fore`` drops blocky
    high-fill clumps that read as stone at motion > 1.
    """
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    if mode == "near":
        shelf = -1
        for y in range(h):
            if _row_frac(px, w, y) >= 0.45:
                shelf = y
                break
        if shelf < 0:
            return out
        tops = _column_tops(px, w, h)
        keep = [False] * w
        for x0, x1, max_h, _mean, _fill, jumps in _stick_spans(tops, shelf):
            fill = _span_fill(px, tops, x0, x1, shelf, max_h)
            if not _keep_near_span(x1 - x0 + 1, max_h, fill, jumps):
                continue
            for x in range(max(0, x0 - 2), min(w, x1 + 3)):
                keep[x] = True
        # Drop sliding dirt lips. Keep a short foot under foliage only.
        foot = shelf + 5
        for x in range(w):
            for y in range(h):
                if px[x, y][3] == 0:
                    continue
                if (not keep[x]) or y >= foot:
                    px[x, y] = (0, 0, 0, 0)
        _settle_to_bottom(out, 4)
        return out
    # Foreground: connected clumps, no dirt shelf.
    opaque = [[px[x, y][3] >= 128 for x in range(w)] for y in range(h)]
    seen = [[False] * w for _ in range(h)]
    for y0 in range(h):
        for x0 in range(w):
            if not opaque[y0][x0] or seen[y0][x0]:
                continue
            stack = [(x0, y0)]
            seen[y0][x0] = True
            cells: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and opaque[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            xs = [c[0] for c in cells]
            ys = [c[1] for c in cells]
            bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)
            bw, bh = bx1 - bx0 + 1, by1 - by0 + 1
            fill = len(cells) / float(max(1, bw * bh))
            peri = 0
            cellset = set(cells)
            for cx, cy in cells:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if (cx + dx, cy + dy) not in cellset:
                        peri += 1
            jag = peri / (len(cells) ** 0.5)
            # Tiny grass stays. Tiny high-fill pebbles go.
            if len(cells) < 16:
                if fill >= 0.58 and bh <= 8:
                    for cx, cy in cells:
                        px[cx, cy] = (0, 0, 0, 0)
                continue
            if _keep_fore_clump(bw, bh, fill, jag):
                continue
            for cx, cy in cells:
                px[cx, cy] = (0, 0, 0, 0)
    return out


def punch_fill(img: Image.Image, thr: int = 46) -> Image.Image:
    """Drop leftover indigo/black mats after quantize. Keeps bark and stone."""
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and max(r, g, b) < thr and r < 10:
                px[x, y] = (0, 0, 0, 0)
    return out


def heal_moon(img: Image.Image) -> Image.Image:
    """Paint out dark cross / sword blobs sitting on the magenta moon disk."""
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    core: list[tuple[int, int]] = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and r > 180 and b > 90 and r >= g + 12:
                core.append((x, y))
    if len(core) < 80:
        return out
    cx = sum(p[0] for p in core) / len(core)
    cy = sum(p[1] for p in core) / len(core)
    dists = sorted(((p[0] - cx) ** 2 + (p[1] - cy) ** 2) ** 0.5 for p in core)
    radius = dists[int(len(dists) * 0.90)]
    samples: list[tuple[int, int, int]] = []
    inner = (radius * 0.65) ** 2
    for y in range(h):
        for x in range(w):
            if (x - cx) ** 2 + (y - cy) ** 2 > inner:
                continue
            r, g, b, a = px[x, y]
            if a > 0 and is_moon_rgb((r, g, b)):
                samples.append((r, g, b))
    if not samples:
        return out
    samples.sort()
    body = samples[len(samples) // 2]
    r2 = (radius * 0.90) ** 2
    for y in range(h):
        for x in range(w):
            if (x - cx) ** 2 + (y - cy) ** 2 > r2:
                continue
            r, g, b, a = px[x, y]
            if a < 1:
                continue
            if r > 120 and b > 50 and r >= g:
                continue
            px[x, y] = (body[0], body[1], body[2], 255)
    return out


def run_job(job: dict) -> Image.Image:
    src = AI / job["src"]
    if not src.is_file():
        raise SystemExit(f"missing AI plate: {src}")
    raw = Image.open(src).convert("RGB")
    x, y, w, h = job["crop"]
    if x + w > raw.size[0] or y + h > raw.size[1]:
        raise SystemExit(f"{job['src']}: crop {job['crop']} exceeds {raw.size}")
    plate = crop_box(raw, job["crop"])
    if job["scrub_warm"]:
        plate = scrub_warm(plate.convert("RGBA")).convert("RGB")
    plate = crunch(plate)
    small = box_down(plate, BOX)
    key = job["key_sky"]
    thr = int(job.get("key_thr", SKY_MAX))
    if key == "all":
        small = key_all_dark(small, thr)
    elif key:
        small = key_above_silhouette(small)
    if job.get("heal_moon"):
        small = heal_moon(small)
    if job["seal"] == "horizon":
        small = seal_horizon(small)
    elif job["seal"] == "feet":
        small = seal_feet(small)
    elif job["seal"] == "full":
        small = seal_silhouette(small)
    wrap = int(job.get("wrap", 0))
    if wrap > 0:
        small = wrap_fade(small, wrap)
    out = quantize_rgba(small, int(job.get("colors", COLORS)))
    if job.get("punch_fill"):
        out = punch_fill(out, int(job.get("punch_thr", 46)))
    soft = job.get("soft_only", "")
    if soft:
        out = strip_hard_soft_only(out, str(soft))
    dst = ENV / job["dst"]
    out.save(dst, "PNG")
    uniq: set[tuple[int, int, int]] = set()
    px = out.load()
    ow, oh = out.size
    for yy in range(oh):
        for xx in range(ow):
            p = px[xx, yy]
            if p[3] > 0:
                uniq.add(p[:3])
    print(
        f"{job['name']}: AI {raw.size} crop {job['crop']} "
        f"BOX/{BOX} colors={COLORS} -> {dst.name} {out.size} unique={len(uniq)}"
    )
    return out


def write_preview(plates: dict[str, Image.Image]) -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    layout = (
        ("parallax_sky_px.png", 0, (255, 255, 255, 255)),
        ("parallax_clouds_px.png", 36, (235, 209, 255, 178)),
        ("parallax_clouds_low_px.png", 78, (224, 199, 245, 140)),
        ("parallax_far_mountains_px.png", 152, (209, 199, 230, 255)),
        ("parallax_mountains_px.png", 178, (255, 255, 255, 255)),
        ("parallax_fog_px.png", 222, (255, 255, 255, 150)),
        ("parallax_mid_grove_px.png", 192, (255, 255, 255, 255)),
        ("parallax_fog_px.png", 248, (255, 255, 255, 170)),
        ("parallax_graveyard_px.png", 192, (255, 255, 255, 255)),
        ("parallax_fog_px.png", 276, (255, 255, 255, 190)),
    )
    canvas = Image.new("RGBA", (768, 520), (18, 12, 28, 255))
    for name, y, mod in layout:
        spr = plates[name].convert("RGBA")
        if mod != (255, 255, 255, 255):
            tinted = Image.new("RGBA", spr.size)
            sp, tp = spr.load(), tinted.load()
            for yy in range(spr.size[1]):
                for xx in range(spr.size[0]):
                    r, g, b, a = sp[xx, yy]
                    if a == 0:
                        continue
                    tp[xx, yy] = (
                        r * mod[0] // 255,
                        g * mod[1] // 255,
                        b * mod[2] // 255,
                        a,
                    )
            spr = tinted
        canvas.alpha_composite(spr, (0, y))
    path = PREVIEW / "parallax_stack_preview.png"
    canvas.save(path, "PNG")
    print(f"preview {path} {canvas.size}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--only", nargs="*", default=None)
    args = parser.parse_args()
    plates: dict[str, Image.Image] = {}
    for job in JOBS:
        if args.only and job["dst"] not in args.only and job["name"] not in args.only:
            dst = ENV / job["dst"]
            if dst.is_file():
                plates[job["dst"]] = Image.open(dst)
            continue
        plates[job["dst"]] = run_job(job)
    if args.preview:
        write_preview(plates)


if __name__ == "__main__":
    main()
