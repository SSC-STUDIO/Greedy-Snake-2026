#!/usr/bin/env python3
"""Distill an 8-frame shrine flame strip from the CC0 CodeManu brightfire sheet.

Runtime NEAREST downscale of the 100px cells loses the wick (see gen_ui_kit.py);
this script area-averages each cropped frame onto a 12x16 design grid and snaps
coverage to the rust/ember ramp so Godot can draw at 1:1.

Run:  py -3 tools/gen_shrine_flame.py
"""
from __future__ import annotations

import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FIRE_SHEET = os.path.join(ROOT, "assets", "kenney_clean", "vfx",
                          "9_brightfire_spritesheet.png")
OUT = os.path.join(ROOT, "assets", "fx", "shrine_flame.png")

FIRE_COLS, FIRE_ROWS, FIRE_FRAMES = 8, 8, 61
CELL_W, CELL_H = 8, 12
SHIP_SCALE = 2
COUNT = 8
FIRST, STEP = 3, 7
ALPHA_CUT = 150

# Same rust→ember ramp as tools/gen_ui_kit.py FIRE_RAMP / PAL.
RAMP = [
    (0x4A, 0x2A, 0x18, 255),  # rust shadow
    (0x8B, 0x45, 0x13, 255),  # rust dark
    (0xA0, 0x52, 0x2D, 255),  # rust mid
    (0xCD, 0x5C, 0x5C, 255),  # rust light
    (0xFF, 0x8C, 0x00, 255),  # toxic/orange glow
    (0xFF, 0xC1, 0x4A, 255),  # ember core
]


def _fire_frame(sheet: Image.Image, index: int) -> Image.Image | None:
    fw, fh = sheet.width // FIRE_COLS, sheet.height // FIRE_ROWS
    col, row = index % FIRE_COLS, index // FIRE_COLS
    cell = sheet.crop((col * fw, row * fh, col * fw + fw, row * fh + fh))
    bbox = cell.split()[3].getbbox()
    return cell.crop(bbox) if bbox is not None else None


def _distill(src: Image.Image) -> list[tuple[int, int, int, int]]:
    small = src.resize((CELL_W, CELL_H), Image.BOX)
    px = small.load()
    out: list[tuple[int, int, int, int]] = []
    for y in range(CELL_H):
        for x in range(CELL_W):
            a = px[x, y][3]
            if a < ALPHA_CUT:
                out.append((0, 0, 0, 0))
                continue
            density = (a - ALPHA_CUT) / float(255 - ALPHA_CUT)
            level = min(len(RAMP) - 1, int(density ** 0.7 * len(RAMP)))
            out.append(RAMP[level])
    return out


def main() -> None:
    sheet = Image.open(FIRE_SHEET).convert("RGBA")
    design = Image.new("RGBA", (CELL_W * COUNT, CELL_H), (0, 0, 0, 0))
    for i in range(COUNT):
        src = _fire_frame(sheet, (FIRST + i * STEP) % FIRE_FRAMES)
        if src is None:
            continue
        cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
        cell.putdata(_distill(src))
        design.paste(cell, (i * CELL_W, 0))
    strip = design.resize(
        (design.width * SHIP_SCALE, design.height * SHIP_SCALE), Image.NEAREST)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    strip.save(OUT)
    print(f"  shrine_flame.png  {strip.width}x{strip.height}  ({COUNT} frames, {SHIP_SCALE}x)")


if __name__ == "__main__":
    main()
