#!/usr/bin/env python3
"""Author the Ember Nest brazier at world 1x (NEAREST, no UI 2x).

The checkpoint used to be rubble_c squeezed to 18×22 — a pebble next to the
80px knight. This is a rusted iron grave-brazier: flared bowl, riveted hoop,
splayed tripod, a dark ash well. Lit coals are a second sheet so the basin
can sit cold until the player lights it; the flame sprite then rises out of
the well (EmberNest.FLAME_POS), not over the bowl body.

Run:  python3 tools/gen_ember_nest.py
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from gen_ui_kit import Grid, outline  # noqa: E402

OUT = os.path.join(ROOT, "assets", "env")
W, H = 48, 36
# Bowl well in sprite space — keep in sync with EmberNest.BOWL via
# BASE_OFFSET + (WELL_CX, WELL_CY).
WELL_CX, WELL_CY = 22, 8


def _ellipse(g: Grid, cx: float, cy: float, rx: float, ry: float, ch: str) -> None:
    rx = max(rx, 0.5)
    ry = max(ry, 0.5)
    for y in range(g.h):
        for x in range(g.w):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                g[x, y] = ch


def _rect(g: Grid, x0: int, y0: int, x1: int, y1: int, ch: str) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[x, y] = ch


def _span(g: Grid, y: int, x0: int, x1: int, ch: str) -> None:
    _rect(g, x0, y, x1, y, ch)


def _put(g: Grid, cells: list[tuple[int, int, str]]) -> None:
    for x, y, ch in cells:
        g[x, y] = ch


def _splay_leg(g: Grid, x_top: float, x_bot: float, y0: int, y1: int,
               width: int = 4) -> None:
    """Iron post that kicks outward toward the grass."""
    span = max(y1 - y0, 1)
    for y in range(y0, y1 + 1):
        t = (y - y0) / span
        x = int(round(x_top + (x_bot - x_top) * t))
        for dx in range(width):
            g[x + dx, y] = "1"
        g[x, y] = "2"
        g[x + width - 1, y] = "7" if y > y0 + 3 else "1"
        if y > y1 - 4:
            g[x, y] = "8"
            g[x + 1, y] = "8"
            g[x + width - 1, y] = "7"
    foot_x = int(round(x_bot))
    _rect(g, foot_x - 1, y1, foot_x + width, y1, "0")
    _rect(g, foot_x, y1 - 1, foot_x + width - 1, y1 - 1, "8")
    g[foot_x, y1] = "8"
    g[foot_x + width - 1, y1] = "7"
    g[foot_x - 1, y1 - 1] = "7"
    g[foot_x + width, y1 - 1] = "1"


def _legs(g: Grid) -> None:
    _splay_leg(g, 10.0, 5.0, 17, 34, 4)
    _splay_leg(g, 31.0, 36.0, 17, 34, 4)
    _splay_leg(g, 20.0, 21.0, 16, 28, 4)
    # Upper stretcher under the bowl.
    _span(g, 17, 12, 34, "1")
    _span(g, 18, 12, 34, "1")
    _span(g, 17, 13, 33, "2")
    _span(g, 18, 13, 33, "8")
    _span(g, 19, 14, 32, "7")
    # Lower cross-brace so the tripod reads as a stand.
    _span(g, 24, 16, 30, "1")
    _span(g, 25, 16, 30, "1")
    _span(g, 24, 17, 29, "2")
    g[17, 25] = "8"
    g[29, 25] = "8"


def _bowl(g: Grid) -> None:
    """Side-on flared basin, drawn as scanlines so the lip and well read."""
    # Rim is the widest slice; the body tapers so it is a vessel, not a can.
    shell = [
        (1, 14, 31),
        (2, 10, 35),
        (3, 8, 37),
        (4, 7, 38),
        (5, 6, 39),
        (6, 6, 39),
        (7, 7, 38),
        (8, 7, 38),
        (9, 8, 37),
        (10, 8, 37),
        (11, 9, 36),
        (12, 10, 35),
        (13, 11, 34),
        (14, 12, 33),
        (15, 13, 32),
        (16, 15, 30),
    ]
    for y, x0, x1 in shell:
        _span(g, y, x0, x1, "8")
        g[x0, y] = "9"
        g[x0 + 1, y] = "9"
        g[x1, y] = "7"
        g[x1 - 1, y] = "7"
        if 4 <= y <= 13:
            _span(g, y, x0 + 2, x1 - 2, "9")
    # Inner well — cold ash, inset so the rim is a 2px lip.
    well = [
        (3, 16, 29, "1"),
        (4, 14, 31, "7"),
        (5, 13, 32, "v"),
        (6, 13, 32, "v"),
        (7, 13, 32, "v"),
        (8, 14, 31, "v"),
        (9, 14, 31, "v"),
        (10, 15, 30, "7"),
        (11, 17, 28, "7"),
    ]
    for y, x0, x1, ch in well:
        _span(g, y, x0, x1, ch)
        g[x0, y] = "1"
        g[x1, y] = "1"
    # Sparse ash, not a regular grate.
    _put(g, [
        (16, 6, "7"), (19, 7, "7"), (24, 6, "7"), (27, 8, "7"),
        (18, 8, "7"), (29, 7, "7"), (15, 8, "7"), (22, 9, "1"),
        (26, 5, "7"), (20, 5, "7"),
    ])
    # Far rim highlight (iron, not pink rust-light) and near-lip shade.
    _span(g, 1, 16, 29, "3")
    _span(g, 2, 12, 33, "3")
    _span(g, 2, 16, 29, "2")
    _span(g, 3, 9, 14, "3")
    _span(g, 3, 31, 36, "2")
    g[7, 5] = "3"
    g[8, 4] = "3"
    # Rivets on the rim.
    for x, y in ((12, 2), (18, 1), (22, 1), (27, 1), (33, 2)):
        g[x, y] = "3"
        g[x, y + 1] = "1"
    # Rust grit on the front wall.
    for x, y in (
        (12, 12), (14, 13), (31, 12), (29, 14), (13, 14),
        (32, 11), (11, 11), (30, 15), (15, 15), (27, 16),
        (10, 10), (33, 10),
    ):
        if g[x, y] in ("8", "9"):
            g[x, y] = "7" if g[x, y] == "8" else "8"
    # No bone chips / jaw in the well: two pale dots in a dark oval read as a
    # face on a signboard from three metres away. Darker ash lumps only.
    _put(g, [
        (16, 8, "7"), (28, 8, "7"), (22, 8, "7"),
        (19, 9, "7"), (25, 9, "1"),
    ])


def _hoop(g: Grid) -> None:
    """Worn iron band around the belly — reads as a vessel, not a blob."""
    _span(g, 13, 12, 33, "1")
    _span(g, 14, 11, 34, "1")
    _span(g, 15, 13, 32, "1")
    _span(g, 13, 13, 32, "2")
    _span(g, 14, 13, 32, "8")
    _span(g, 15, 14, 31, "7")
    for x in (14, 22, 31):
        g[x, 13] = "3"
        g[x, 14] = "1"
    g[22, 14] = "9"


def build_nest() -> Grid:
    # No chain-and-skull charm off the rim: a dangling rope on one side made the
    # basin read as a hung signboard rather than a standing brazier.
    g = Grid(W, H, ".")
    _legs(g)
    _bowl(g)
    _hoop(g)
    outline(g, "0")
    return g


def build_coals() -> Grid:
    g = Grid(W, H, ".")
    cx, cy = float(WELL_CX), float(WELL_CY) - 1.2
    _ellipse(g, cx, cy, 11.0, 4.0, "9")
    _ellipse(g, cx, cy - 0.3, 8.4, 2.8, "b")
    _ellipse(g, cx, cy - 0.7, 5.2, 1.6, "c")
    for x, y, ch in (
        (14, 10, "c"), (30, 11, "c"), (18, 12, "b"),
        (26, 9, "c"), (22, 11, "d"), (20, 10, "c"),
    ):
        g[x, y] = ch
    return g


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    build_nest().to_image(1).save(os.path.join(OUT, "ember_nest.png"))
    build_coals().to_image(1).save(os.path.join(OUT, "ember_nest_coals.png"))
    print(f"  ember_nest.png        {W}x{H}")
    print(f"  ember_nest_coals.png   {W}x{H}")


if __name__ == "__main__":
    main()
