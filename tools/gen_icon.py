"""Generate Rustgrave's app icon into icon.png + icon.ico.

The icon is authored on a **16x16 design grid**, because 16px is the smallest
size Windows asks for and every other required size is a whole multiple of it
(32 = 2x, 48 = 3x, 64 = 4x, 128 = 8x, 256 = 16x). Authoring at the smallest
size and only ever scaling up by whole numbers means no size can blur, and the
16px taskbar icon is the *original* art rather than a downsample of something
detailed.

Subject: the knight's rust greatsword planted point-down — the title reads
"锈墓", and a blade standing in the ground is both the grave marker and the
weapon. Its silhouette is a cross, which is about the only shape that survives
16px intact.

Nothing here is traced from the title keyart. That keyart is AI-generated
(see assets/external/CREDITS.md), so cropping it would have made the app icon
AI-derived. Its knight-with-raised-greatsword was tried as a silhouette anyway
(crop, hard threshold to 1-bit, coverage-average onto the grid) and failed on
its own terms too: the pose only gets ~10 cells inside the plate and collapses
into an ambiguous diagonal streak, because a standing human figure has no
readable silhouette at 16px. Palette, plate and lighting come from the UI kit,
so the icon still reads as part of the same set as the HUD.

Run:  py -3 tools/gen_icon.py
"""

from __future__ import annotations

import os
import struct

from PIL import Image

from gen_ui_kit import Grid, frame

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

## 图标设计栅格；下面所有导出尺寸都是它的整数倍。
GRID = 16
## icon.png 的边长（256 = 16x）。
PNG_SIZE = 256
## .ico 里打包的尺寸，全部是 GRID 的整数倍。
ICO_SIZES = (16, 32, 48, 64, 128, 256)

## 竖插的锈剑，画在 12x12 的内腔里（' ' 表示露出底板）。
## 光从左上来：护手上沿与剑身左沿提亮，下沿与右沿压暗，护手中心一颗余烬宝石。
## 四周刻意各留一格暗紫缝隙 —— 贴着锈色外框的话，剑会读成框上的一根横梁。
BLADE_ART = [
    ".....99.....",
    ".....87.....",
    "..999cc999..",
    "..77777777..",
    "....c998....",
    ".....c8.....",
    ".....c8.....",
    ".....c8.....",
    ".....c8.....",
    ".....78.....",
]
BLADE_AT = (2, 3)


def build() -> Grid:
    """Chamfered rust plate with the planted greatsword stamped into it."""
    g = frame(GRID, GRID, [("0", "0"), ("9", "8")], "4", chamfer=2)
    g.stamp(BLADE_AT[0], BLADE_AT[1], [row.replace(".", " ") for row in BLADE_ART])
    return g


def write_ico(base: Image.Image, path: str) -> None:
    """Pack NEAREST upscales into a multi-size .ico.

    Written by hand instead of via Image.save(sizes=...): PIL resamples the
    frames itself with a smoothing filter, which is exactly what this icon must
    never suffer. Each entry is a PNG payload, which Windows has accepted at
    every size since Vista.
    """
    frames = []
    for size in ICO_SIZES:
        scaled = base.resize((size, size), Image.NEAREST)
        buf = os.path.join(os.path.dirname(path), f".ico_{size}.png")
        scaled.save(buf)
        with open(buf, "rb") as fh:
            frames.append((size, fh.read()))
        os.remove(buf)

    header = struct.pack("<HHH", 0, 1, len(frames))
    offset = len(header) + 16 * len(frames)
    entries, payloads = b"", b""
    for size, data in frames:
        # ICO 用一个字节存边长，256 只能写 0。
        entries += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32,
                               len(data), offset)
        payloads += data
        offset += len(data)
    with open(path, "wb") as fh:
        fh.write(header + entries + payloads)
    print(f"  {'icon.ico':<26} {'/'.join(str(s) for s in ICO_SIZES)}")


def write_contact_sheet(base: Image.Image, path: str) -> None:
    """Side-by-side of every shipped size, each blown up for eyeballing."""
    zoom = {16: 8, 32: 4, 48: 3, 64: 2, 128: 1, 256: 1}
    pad = 12
    tiles = [(s, base.resize((s, s), Image.NEAREST)) for s in ICO_SIZES]
    width = sum(s * zoom[s] for s, _ in tiles) + pad * (len(tiles) + 1)
    height = max(s * zoom[s] for s, _ in tiles) + pad * 2
    sheet = Image.new("RGBA", (width, height), (26, 20, 32, 255))
    x = pad
    for size, tile in tiles:
        big = tile.resize((size * zoom[size], size * zoom[size]), Image.NEAREST)
        sheet.alpha_composite(big, (x, pad))
        x += big.width + pad
    sheet.save(path)
    print(f"  {os.path.basename(path):<26} {sheet.width}x{sheet.height}")


def main() -> None:
    base = build().to_image(scale=1)

    print("generating icon ...")
    base.resize((PNG_SIZE, PNG_SIZE), Image.NEAREST).save(os.path.join(ROOT, "icon.png"))
    print(f"  {'icon.png':<26} {PNG_SIZE}x{PNG_SIZE}")
    write_ico(base, os.path.join(ROOT, "icon.ico"))

    sheet_dir = os.path.join(ROOT, "screenshots", "ui")
    os.makedirs(sheet_dir, exist_ok=True)
    write_contact_sheet(base, os.path.join(sheet_dir, "icon_sizes.png"))


if __name__ == "__main__":
    main()
