#!/usr/bin/env python3
"""Rebuild the in-game derivatives without touching source artwork.

Run from any directory: python tools/normalize_scene_art.py [--check]
All colour edits preserve source alpha. Only the explicitly selected moon is
masked; opaque cathedral plates are assembled on a continuous wall, not keyed.
Animation frames share one canvas size and nearest-neighbour reduction.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
ENV = ROOT / "assets/env"
OUT = ENV / "normalized"


def grade(image: Image.Image, saturation: float, brightness: float = 1.0) -> Image.Image:
    image = image.convert("RGBA")
    rgb = ImageEnhance.Color(image.convert("RGB")).enhance(saturation)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    result = rgb.convert("RGBA")
    result.putalpha(image.getchannel("A"))
    return result


def outputs() -> dict[Path, Image.Image]:
    result = {}
    for source in sorted(ENV.glob("parallax_*_px.png")):
        result[OUT / source.name] = grade(Image.open(source), 0.38, 0.88)

    # Moon source is already the project's approved pixel plate. Crop its
    # authored disk, retain interior source colours/texture, reduce offline.
    sky = Image.open(ENV / "parallax_sky_px.png").convert("RGBA")
    best = (0, 0, 0)
    for y in range(sky.height):
        start = None
        for x in range(sky.width + 1):
            r, g, b, a = sky.getpixel((min(x, sky.width - 1), y))
            is_moon = x < sky.width and a > 0 and r > 150 and b > 70 and r >= g + 12
            if is_moon and start is None:
                start = x
            elif not is_moon and start is not None:
                if x - start > best[0]:
                    best = (x - start, start, y)
                start = None
    width, left, cy = best
    if width < 40:
        raise ValueError("Authored moon disk was not found; do not replace it with invented art")
    cx = left + (width - 1) / 2
    radius = width / 2
    box = (int(cx - radius), int(cy - radius), int(cx + radius), int(cy + radius))
    moon = sky.crop(box)
    for y in range(moon.height):
        for x in range(moon.width):
            if (x - moon.width / 2) ** 2 + (y - moon.height / 2) ** 2 > (radius - 1) ** 2:
                moon.putpixel((x, y), (0, 0, 0, 0))
    result[OUT / "moon.png"] = grade(moon.resize((56, 56), Image.Resampling.NEAREST), 0.16, 0.78)

    # These are opaque room-background plates. Their shared background colour
    # is retained across the entire building rather than removed by colour key.
    wall = Image.new("RGBA", (464, 192), (39, 38, 56, 255))
    for source, position in [
        ("column_big.png", (26, 2)),
        ("bg_column_skulls.png", (116, 0)),
        ("column_big.png", (246, 2)),
        ("bg_altar.png", (300, 0)),
    ]:
        wall.alpha_composite(Image.open(ENV / source).convert("RGBA"), position)
    result[OUT / "cathedral_wall.png"] = grade(wall, 0.55, 0.92)

    prop_source = ROOT / "assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects"
    sign = Image.open(ROOT / "assets/kenney_clean/interactables/sign.png").convert("RGBA")
    result[OUT / "props" / "waymark_sign.png"] = sign.resize((35, 35), Image.Resampling.NEAREST)
    for name, scales in {
        "tree-1": (48,), "tree-2": (44, 46), "tree-3": (38,),
        "bush-large": (42, 50, 62, 65), "bush-small": (70,),
    }.items():
        original = Image.open(prop_source / f"{name}.png").convert("RGBA")
        for percent in scales:
            size = tuple(max(1, round(d * percent / 100)) for d in original.size)
            result[OUT / "props" / f"{name}_{percent}.png"] = original.resize(size, Image.Resampling.NEAREST)

    for source in sorted((ROOT / "assets/characters/flying_demon").glob("*/*.png")):
        original = Image.open(source).convert("RGBA")
        size = tuple(max(1, round(d * 0.45)) for d in original.size)
        result[ROOT / "assets/characters/flying_demon_px" / source.parent.name / source.name] = original.resize(size, Image.Resampling.NEAREST)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify derivatives without writing")
    args = parser.parse_args()
    generated = outputs()
    for destination, image in generated.items():
        if args.check:
            if not destination.exists():
                raise SystemExit(f"Missing derivative: {destination.relative_to(ROOT)}")
            stored = Image.open(destination).convert("RGBA")
            if stored.size != image.size or stored.tobytes() != image.tobytes():
                raise SystemExit(f"Stale derivative: {destination.relative_to(ROOT)}")
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            image.save(destination, optimize=True)
    print(f"{'Verified' if args.check else 'Generated'} {len(generated)} scene derivatives; source artwork unchanged")


if __name__ == "__main__":
    main()
