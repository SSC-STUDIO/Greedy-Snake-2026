#!/usr/bin/env python3
"""Build Greedy Snake 2026 forest assets from AI-generated source images.

This script intentionally does not draw synthetic gameplay art. It only crops,
keys, trims, resizes, and lightly sharpens AI-generated source images so Godot
can consume consistent high-resolution PNG textures.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets/generated/forest_25d"
SOURCE_DIR = ASSET_ROOT / "_ai_source"
SLICE_DIR = ASSET_ROOT / "slices"

SOURCES = {
    "forest_floor": SOURCE_DIR / "forest_floor_ai_20260502.png",
    "dirt_path": SOURCE_DIR / "dirt_path_ai_20260502.png",
    "obstacles": SOURCE_DIR / "obstacle_sheet_ai_20260502.png",
    "foreground_branch": SOURCE_DIR / "foreground_branch_ai_20260502.png",
    "pickups": SOURCE_DIR / "pickup_sheet_ai_20260502.png",
    "menu_background": SOURCE_DIR / "menu_background_ai_20260502.png",
}

OBSTACLE_CELLS = {
    "tree_canopy": (0, 0, (768, 896)),
    "stump": (1, 0, (640, 640)),
    "rock": (2, 0, (640, 640)),
    "root_cluster": (0, 1, (896, 640)),
    "bush": (1, 1, (640, 512)),
    "fallen_log": (2, 1, (896, 512)),
}

PICKUP_CELLS = {
    "food_berry": (0, 0, (384, 384)),
    "leaf_shield_ring": (1, 0, (512, 512)),
    "spore_boost_puff": (2, 0, (512, 384)),
}


def _ensure_dirs() -> None:
    SLICE_DIR.mkdir(parents=True, exist_ok=True)


def _load(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Missing AI source image: {path}")
    return Image.open(path).convert("RGBA")


def _save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


def _cover_resize(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    source_w, source_h = img.size
    scale = max(target_w / source_w, target_h / source_h)
    resized = img.resize((math.ceil(source_w * scale), math.ceil(source_h * scale)), Image.Resampling.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = max(0, (resized.height - target_h) // 2)
    return resized.crop((left, top, left + target_w, top + target_h))


def _fit_on_canvas(img: Image.Image, size: tuple[int, int], fill_ratio: float = 0.86) -> Image.Image:
    target_w, target_h = size
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", size, (0, 0, 0, 0))
    cropped = img.crop(bbox)
    scale = min((target_w * fill_ratio) / cropped.width, (target_h * fill_ratio) / cropped.height)
    new_size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    resized = cropped.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((target_w - new_size[0]) // 2, (target_h - new_size[1]) // 2))
    return canvas


def _remove_magenta_key(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Generated sheets use a flat magenta key with slight compression and
            # lighting drift. Remove only the key family, not berry reds or leaf rims.
            key_strength = min(r, b) - g
            is_key = r > 170 and b > 150 and g < 115 and key_strength > 95
            if is_key:
                hard = min(255, max(0, int((key_strength - 95) * 2.6)))
                alpha = 255 - hard
                pixels[x, y] = (r, g, b, min(a, alpha))
            elif a < 255:
                pixels[x, y] = (r, g, b, a)
    alpha = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(0.45))
    alpha = ImageEnhance.Contrast(alpha).enhance(1.35)
    rgba.putalpha(alpha)
    return _despill_magenta(rgba)


def _despill_magenta(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if 0 < a < 245 and r > g and b > g:
                r = min(r, max(g + 42, int(r * 0.72)))
                b = min(b, max(g + 42, int(b * 0.72)))
                pixels[x, y] = (r, g, b, a)
    return rgba


def _prune_alpha_islands(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    mask = alpha.point(lambda value: 255 if value > 24 else 0)
    visited = bytearray(width * height)
    mp = mask.load()
    components: list[dict] = []
    for y in range(height):
        row_offset = y * width
        for x in range(width):
            index = row_offset + x
            if visited[index] or mp[x, y] == 0:
                continue
            stack = [(x, y)]
            visited[index] = 1
            pixels: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y
            while stack:
                px, py = stack.pop()
                pixels.append((px, py))
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                min_y = min(min_y, py)
                max_y = max(max_y, py)
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    n_index = ny * width + nx
                    if visited[n_index] or mp[nx, ny] == 0:
                        continue
                    visited[n_index] = 1
                    stack.append((nx, ny))
            components.append({
                "pixels": pixels,
                "area": len(pixels),
                "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                "center": ((min_x + max_x + 1) * 0.5, (min_y + max_y + 1) * 0.5),
            })
    if len(components) <= 1:
        return rgba
    components.sort(key=lambda component: component["area"], reverse=True)
    main = components[0]
    main_center = main["center"]
    main_area = float(main["area"])
    main_bbox = main["bbox"]
    keep: set[int] = set()
    max_keep_distance = max(main_bbox[2] - main_bbox[0], main_bbox[3] - main_bbox[1]) * 0.45
    for component in components:
        cx, cy = component["center"]
        distance = math.hypot(cx - main_center[0], cy - main_center[1])
        area_ratio = float(component["area"]) / main_area
        # Keep the main object and nearby spark/leaves. Drop distant islands from
        # adjacent AI sheet cells, even when they are moderately sized.
        if component is main or (distance <= max_keep_distance and area_ratio >= 0.00018):
            for px, py in component["pixels"]:
                keep.add(py * width + px)
    ap = alpha.load()
    for y in range(height):
        for x in range(width):
            if ap[x, y] > 0 and y * width + x not in keep:
                ap[x, y] = 0
    rgba.putalpha(alpha)
    return rgba

def _crop_grid(sheet: Image.Image, columns: int, rows: int, col: int, row: int) -> Image.Image:
    cell_w = sheet.width // columns
    cell_h = sheet.height // rows
    return sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))


def _make_path_patch(path_texture: Image.Image) -> Image.Image:
    patch = _cover_resize(path_texture, (1024, 512))
    alpha = Image.new("L", patch.size, 0)
    ap = alpha.load()
    width, height = patch.size
    for y in range(height):
        vertical = 1.0 - abs((y + 0.5) / height - 0.5) * 2.0
        for x in range(width):
            horizontal = 1.0 - abs((x + 0.5) / width - 0.5) * 2.0
            edge = min(1.0, vertical * 2.6, horizontal * 4.8)
            ap[x, y] = max(0, min(210, int(edge * 210)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(10.0))
    patch.putalpha(alpha)
    return patch

def _make_height_overlay(floor: Image.Image) -> Image.Image:
    gray = floor.convert("L")
    low = gray.filter(ImageFilter.GaussianBlur(12.0))
    high = ImageChops.subtract(gray, low, scale=1.4, offset=132)
    high = ImageEnhance.Contrast(high).enhance(1.55)
    color = Image.new("RGBA", floor.size, (116, 150, 74, 0))
    alpha = high.point(lambda value: max(0, min(82, int((value - 92) * 0.78))))
    color.putalpha(alpha)
    return color


def _polish_texture(img: Image.Image, contrast: float, sharpness: float) -> Image.Image:
    out = img.convert("RGBA")
    out = ImageEnhance.Contrast(out).enhance(contrast)
    out = ImageEnhance.Sharpness(out).enhance(sharpness)
    return out



def _build_ground() -> list[str]:
    outputs: list[str] = []
    floor = _cover_resize(_load(SOURCES["forest_floor"]), (2048, 2048))
    floor = _polish_texture(floor, 1.08, 1.18)
    _save(floor, SLICE_DIR / "forest_floor.png")
    outputs.append("slices/forest_floor.png")

    path = _cover_resize(_load(SOURCES["dirt_path"]), (2048, 2048))
    path = _polish_texture(path, 1.06, 1.16)
    _save(path, SLICE_DIR / "dirt_path.png")
    outputs.append("slices/dirt_path.png")

    path_patch = _make_path_patch(path)
    _save(path_patch, SLICE_DIR / "dirt_path_patch.png")
    outputs.append("slices/dirt_path_patch.png")

    overlay = _make_height_overlay(floor)
    _save(overlay, SLICE_DIR / "ground_height_overlay.png")
    outputs.append("slices/ground_height_overlay.png")
    return outputs


def _build_obstacles() -> list[str]:
    outputs: list[str] = []
    sheet = _load(SOURCES["obstacles"])
    for name, (col, row, size) in OBSTACLE_CELLS.items():
        cell = _crop_grid(sheet, 3, 2, col, row)
        keyed = _remove_magenta_key(cell)
        sprite = _fit_on_canvas(keyed, size, 0.9 if name == "tree_canopy" else 0.84)
        sprite = _prune_alpha_islands(sprite)
        sprite = ImageEnhance.Sharpness(sprite).enhance(1.1)
        _save(sprite, SLICE_DIR / f"{name}.png")
        outputs.append(f"slices/{name}.png")
    return outputs


def _build_foreground() -> list[str]:
    source = _load(SOURCES["foreground_branch"])
    keyed = _remove_magenta_key(source)
    branch = _fit_on_canvas(keyed, (2048, 768), 0.94)
    branch = _prune_alpha_islands(branch)
    branch = ImageEnhance.Sharpness(branch).enhance(1.08)
    _save(branch, SLICE_DIR / "foreground_branch.png")
    return ["slices/foreground_branch.png"]


def _build_pickups() -> list[str]:
    outputs: list[str] = []
    sheet = _load(SOURCES["pickups"])
    # The generator returned a horizontal row with generous vertical key space.
    for name, (col, _row, size) in PICKUP_CELLS.items():
        cell = _crop_grid(sheet, 3, 1, col, 0)
        keyed = _remove_magenta_key(cell)
        sprite = _fit_on_canvas(keyed, size, 0.82)
        sprite = _prune_alpha_islands(sprite)
        sprite = ImageEnhance.Sharpness(sprite).enhance(1.12)
        _save(sprite, SLICE_DIR / f"{name}.png")
        outputs.append(f"slices/{name}.png")
    return outputs


def _build_menu_background() -> list[str]:
    bg = _load(SOURCES["menu_background"])
    bg = _cover_resize(bg, (3840, 2160)).convert("RGB")
    bg = ImageEnhance.Contrast(bg).enhance(1.04)
    bg = ImageEnhance.Sharpness(bg).enhance(1.08)
    _save(bg, ASSET_ROOT / "menu_background.png")
    return ["menu_background.png"]


def main() -> None:
    _ensure_dirs()
    outputs: list[str] = []
    outputs.extend(_build_menu_background())
    outputs.extend(_build_ground())
    outputs.extend(_build_obstacles())
    outputs.extend(_build_foreground())
    outputs.extend(_build_pickups())
    manifest = {
        "source": {key: str(path.relative_to(ROOT)) for key, path in SOURCES.items()},
        "style": "AI-generated realistic 2.5D forest/jungle assets; local processing is crop/key/resize only",
        "preserves_snake_assets": True,
        "replaces_procedural_art": True,
        "outputs": outputs,
    }
    (ASSET_ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Built AI forest assets:")
    for output in outputs:
        print(f"- {output}")


if __name__ == "__main__":
    main()
