#!/usr/bin/env python3
"""Crop 16x16 Gothicvania cemetery/church tiles and cover the title watermark.

Idempotent: re-running rewrites every derived texture in assets/env from the
untouched source sheets. Run from anywhere; paths resolve relative to repo.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CEM = ROOT / "assets/external/gothicvania_cemetery/PNG/Environment/tileset.png"
CHURCH = ROOT / "assets/env/tiles_gothic.png"
ENV = ROOT / "assets/env"
KEYART = ROOT / "assets/kenney_clean/backgrounds/title_keyart.png"
TILE = 16


def crop_cell(im: Image.Image, c: int, r: int, cols: int = 1, rows: int = 1) -> Image.Image:
    x0, y0 = c * TILE, r * TILE
    return im.crop((x0, y0, x0 + cols * TILE, y0 + rows * TILE)).convert("RGBA")


def hue_sludge(src: Image.Image) -> Image.Image:
    """Murky corrosive liquid: dark teal body that fades darker with depth."""
    out = src.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        depth = 1.0 - 0.55 * (y / max(1, h - 1))  # 1.0 top -> 0.45 bottom
        for x in range(w):
            r, g, b, a = px[x, y]
            nr = int((r * 0.14 + 8) * depth)
            ng = int((g * 0.30 + 40) * depth)
            nb = int((b * 0.26 + 32) * depth)
            px[x, y] = (min(255, nr), min(255, ng), min(255, nb), 255)
    return out


def scum_surface(grass: Image.Image) -> Image.Image:
    """Bright toxic film for the pool's top row, with a hot 1px rim light."""
    out = grass.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                # Fill holes with dark teal so the surface is a solid strip.
                px[x, y] = (14, 48, 38, 220)
                continue
            nr = min(255, int(r * 0.45 + 12))
            ng = min(255, int(g * 0.75 + 48))
            nb = min(255, int(b * 0.40 + 36))
            px[x, y] = (nr, ng, nb, 255)
    # Rim light: brighten the topmost opaque pixel of each column.
    for x in range(w):
        for y in range(h):
            r, g, b, a = px[x, y]
            if a >= 200:
                px[x, y] = (min(255, r + 70), min(255, g + 90), min(255, b + 60), 255)
                break
    return out


def roll_x(src: Image.Image, dx: int) -> Image.Image:
    """Horizontal wrap-shift (second animation frame for the scum surface)."""
    out = Image.new("RGBA", src.size)
    out.paste(src.crop((dx, 0, src.width, src.height)), (0, 0))
    out.paste(src.crop((0, 0, dx, src.height)), (src.width - dx, 0))
    return out


def fog_band(w: int = 256, h: int = 64) -> Image.Image:
    """Soft tileable mist strip: pale lavender, alpha peaks near the middle."""
    out = Image.new("RGBA", (w, h))
    px = out.load()
    for y in range(h):
        t = y / (h - 1)
        # Smooth bump: 0 at top, peak ~0.62 around t=0.55, 0 at bottom.
        k = max(0.0, 1.0 - abs(t - 0.55) / 0.55)
        alpha = int(255 * 0.62 * k * k)
        for x in range(w):
            px[x, y] = (204, 192, 228, alpha)
    return out


def glow_soft(size: int = 48) -> Image.Image:
    """Outline-free radial ember glow (hook anchors, pickups)."""
    out = Image.new("RGBA", (size, size))
    px = out.load()
    c = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            k = max(0.0, 1.0 - d)
            alpha = int(255 * (k ** 2.2))
            px[x, y] = (255, 168, 92, alpha)
    return out


def wrap_fade(src: Image.Image, band: int = 32) -> Image.Image:
    """Make a texture horizontally seamless by overlap-crossfade.

    Output is (w - band) wide: the last `band` source columns get blended
    into the first `band` output columns, so column w'-1 flows into column 0.
    """
    w, h = src.size
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


def sky_repaint(src: Image.Image) -> Image.Image:
    """Lift the near-black cloud corners toward the maroon sky palette.

    The raw Gothicvania sky has huge navy-black cloud masses at both ends;
    on screen they read as 'the background ended' (bare dark purple wall),
    and the equally dark mountain silhouettes vanish against them.
    """
    out = src.convert("RGB").copy()
    px = out.load()
    w, h = out.size
    tr, tg, tb = 74, 26, 62  # deep maroon-purple target
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            lum = 0.3 * r + 0.59 * g + 0.11 * b
            if lum < 70:
                f = (70 - lum) / 70 * 0.55
                px[x, y] = (
                    int(r + (tr - r) * f),
                    int(g + (tg - g) * f),
                    int(b + (tb - b) * f),
                )
    return wrap_fade(out, 32)


def mountains_lift(src: Image.Image) -> Image.Image:
    """Flat purple lift so the silhouette stays readable over dark sky clouds."""
    out = src.convert("RGBA").copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 30:
                px[x, y] = (min(255, r + 22), min(255, g + 12), min(255, b + 40), a)
    return out


def cover_watermark(path: Path) -> None:
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    # Sample a dark nearby pixel (left of the badge).
    sample = px[max(0, w - 300), min(h - 1, h - 18)]
    x0, y0 = w - 250, h - 46
    for y in range(y0, h):
        for x in range(x0, w):
            # Soft-ish edge: blend 10px from the left/top of the patch.
            tx = min(1.0, (x - x0) / 14.0)
            ty = min(1.0, (y - y0) / 10.0)
            t = min(tx, ty)
            r, g, b = px[x, y]
            px[x, y] = (
                int(r + (sample[0] - r) * t),
                int(g + (sample[1] - g) * t),
                int(b + (sample[2] - b) * t),
            )
    im.save(path)
    print("watermark covered:", path, "sample", sample)


def main() -> None:
    cem = Image.open(CEM).convert("RGBA")
    church = Image.open(CHURCH).convert("RGBA")

    crops = {
        # Surface grass row.
        "tile_top_a.png": crop_cell(cem, 4, 4),
        "tile_top_b.png": crop_cell(cem, 5, 4),
        "tile_top_c.png": crop_cell(cem, 7, 4),
        "tile_top_left.png": crop_cell(cem, 1, 4),   # grass cap, open left edge
        "tile_top_right.png": crop_cell(cem, 12, 4),  # grass cap, open right edge
        # Dirt fills: quiet variants carry the bulk, skulls stay rare accents.
        "tile_fill_dark.png": crop_cell(cem, 4, 5),
        "tile_fill_b.png": crop_cell(cem, 5, 5),
        "tile_fill_skull.png": crop_cell(cem, 1, 5),
        "tile_fill_plain.png": crop_cell(cem, 11, 5),
        "tile_fill_plain_b.png": crop_cell(cem, 2, 5),
        "tile_fill_edge_l.png": crop_cell(cem, 1, 5),
        "tile_fill_edge_r.png": crop_cell(cem, 12, 5),
        # Depth transition: dirt fading into darkness, then near-black.
        "tile_fill_fade_a.png": crop_cell(cem, 1, 6),
        "tile_fill_fade_b.png": crop_cell(cem, 12, 6),
        "tile_fill_deep.png": crop_cell(cem, 2, 6),
        "door_arch.png": crop_cell(church, 18, 1, 2, 4),  # 32x64 gothic arch
        "socket_altar.png": crop_cell(church, 12, 2, 2, 3),  # 32x48 candles
    }
    for name, img in crops.items():
        dest = ENV / name
        img.save(dest)
        print("wrote", dest.name, img.size, "alpha", img.getchannel("A").getextrema())

    # Flat church-stone lip -> pressure plate (32x10, no squash).
    plate = church.crop((4 * TILE, 7 * TILE, 6 * TILE, 7 * TILE + 10)).convert("RGBA")
    plate.save(ENV / "plate_stone.png")
    print("wrote plate_stone.png", plate.size)

    # Floating stone platforms: church "hovering island" chunk at x0-48,
    # rows 10-12 — pale slab top face + dark ragged rock hanging underneath.
    # Content starts at y=168 -> sprite y=0 == walkable top. mid_b is a
    # mirrored mid_a so long platforms don't strobe one identical column.
    floats = {
        "float_left.png": (0, 168, 16, 208),
        "float_mid_a.png": (16, 168, 32, 208),
        "float_right.png": (32, 168, 48, 208),
        "float_small.png": (192, 160, 224, 192),  # 2-tile hovering block
    }
    for name, box in floats.items():
        img = church.crop(box).convert("RGBA")
        img.save(ENV / name)
        print("wrote", name, img.size)
    mid_b = church.crop(floats["float_mid_a.png"]).convert("RGBA")
    mid_b = mid_b.transpose(Image.FLIP_LEFT_RIGHT)
    mid_b.save(ENV / "float_mid_b.png")
    print("wrote float_mid_b.png", mid_b.size)

    # Parallax set: seamless sky (352x224 after edge crossfade) + lifted
    # mountains. Always rebuilt from the untouched external sources.
    ext = ROOT / "assets/external/gothicvania_cemetery/PNG/Environment"
    sky = sky_repaint(Image.open(ext / "background.png"))
    sky.save(ENV / "parallax_sky.png")
    print("wrote parallax_sky.png", sky.size)
    mts = mountains_lift(Image.open(ext / "mountains.png"))
    mts.save(ENV / "parallax_mountains.png")
    print("wrote parallax_mountains.png", mts.size)

    sludge = hue_sludge(crop_cell(cem, 2, 5))
    sludge.save(ENV / "toxin_sludge.png")
    print("wrote toxin_sludge.png", sludge.size)
    scum = scum_surface(crop_cell(cem, 2, 4).crop((0, 0, 16, 5)))
    scum.save(ENV / "toxin_scum.png")
    roll_x(scum, 8).save(ENV / "toxin_scum_b.png")
    print("wrote toxin_scum.png + toxin_scum_b.png", scum.size)

    fog = fog_band()
    fog.save(ENV / "fog_band.png")
    print("wrote fog_band.png", fog.size)

    glow = glow_soft()
    glow.save(ENV / "glow_soft.png")
    print("wrote glow_soft.png", glow.size)

    cover_watermark(KEYART)


if __name__ == "__main__":
    main()
