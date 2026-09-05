"""Summarize a rendered display acceptance run and make reviewable image sheets.

The renderer writes a JSON report and native root render-target PNGs.  This tool
keeps the report generation deterministic and deliberately does not launch
Godot or claim that fixture captures prove a playable/completable game.
"""

from __future__ import annotations

import argparse
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


DEFAULT_REPORT = Path("screenshots/acceptance/display/report.json")


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Load a Windows font when present, with PIL's fallback otherwise."""

    for candidate in (Path("C:/Windows/Fonts/msyh.ttc"), Path("C:/Windows/Fonts/arial.ttf")):
        if candidate.exists():
            try:
                return ImageFont.truetype(str(candidate), size)
            except OSError:
                pass
    return ImageFont.load_default()


def _as_size(value: Any) -> tuple[int, int] | None:
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        return None
    try:
        return (int(round(float(value[0]))), int(round(float(value[1]))))
    except (TypeError, ValueError):
        return None


def _fmt_size(value: Any) -> str:
    size = _as_size(value)
    return f"{size[0]}×{size[1]}" if size else "—"


def _fmt_rect(value: Any) -> str:
    if not isinstance(value, (list, tuple)) or len(value) != 4:
        return "—"
    try:
        return "(" + ", ".join(f"{float(part):.2f}" for part in value) + ")"
    except (TypeError, ValueError):
        return "—"


def _safe_name(value: Any) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def _entry_image_path(root: Path, entry: dict[str, Any]) -> Path | None:
    filename = entry.get("png")
    if not isinstance(filename, str) or not filename:
        return None
    path = root / filename
    return path if path.is_file() else None


def _load_entries(data: dict[str, Any], root: Path) -> tuple[list[dict[str, Any]], list[str]]:
    entries: list[dict[str, Any]] = []
    issues: list[str] = []
    raw_entries = data.get("resolutions", [])
    if not isinstance(raw_entries, list):
        return entries, ["report.resolutions is not a list"]
    for raw in raw_entries:
        if not isinstance(raw, dict):
            issues.append("ignored non-object resolution entry")
            continue
        entry = dict(raw)
        path = _entry_image_path(root, entry)
        entry["_path"] = path
        entry["_actual_png_size"] = None
        if path is None:
            issues.append(f"missing PNG for {entry.get('fixture', '?')}: {entry.get('png', '?')}")
        else:
            try:
                with Image.open(path) as image:
                    entry["_actual_png_size"] = image.size
            except OSError as exc:
                issues.append(f"could not read {path.name}: {exc}")
        requested = _as_size(entry.get("requested"))
        actual = entry["_actual_png_size"]
        declared = _as_size(entry.get("rendered_image_size"))
        # Native offscreen runs may expose the fixed root render target
        # (1280×720) while the requested window is larger; the Godot report's
        # window_size and renderer checks remain authoritative in that mode.
        if declared and actual and declared != actual:
            issues.append(f"{path.name}: declared rendered_image_size {_fmt_size(declared)} differs from PNG {_fmt_size(actual)}")
        if raw.get("passed") is False:
            issues.append(f"fixture failed renderer checks: {entry.get('fixture', '?')}")
        entries.append(entry)
    return entries, issues


def _load_title_entries(data: dict[str, Any], root: Path) -> tuple[list[dict[str, Any]], list[str]]:
    entries: list[dict[str, Any]] = []
    issues: list[str] = []
    raw_entries = data.get("title_screens", [])
    if not isinstance(raw_entries, list):
        return entries, ["report.title_screens is not a list"]
    for raw in raw_entries:
        if not isinstance(raw, dict):
            issues.append("ignored non-object title screen entry")
            continue
        entry = dict(raw)
        path = _entry_image_path(root, entry)
        entry["_path"] = path
        entry["_actual_png_size"] = None
        if path is None:
            issues.append(f"missing title PNG: {entry.get('png', '?')}")
        else:
            try:
                with Image.open(path) as image:
                    entry["_actual_png_size"] = image.size
            except OSError as exc:
                issues.append(f"could not read {path.name}: {exc}")
        requested = _as_size(entry.get("requested"))
        actual = entry["_actual_png_size"]
        if raw.get("passed") is False:
            issues.append(f"title bounds failed renderer checks: {entry.get('png', '?')}")
        entries.append(entry)
    return entries, issues


def _fit_image(image: Image.Image, box: tuple[int, int], *, background: tuple[int, int, int]) -> Image.Image:
    width, height = box
    result = Image.new("RGB", box, background)
    source = image.convert("RGB")
    scale = min(width / source.width, height / source.height)
    target = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    resized = source.resize(target, Image.Resampling.NEAREST)
    result.paste(resized, ((width - target[0]) // 2, (height - target[1]) // 2))
    return result


def _make_fixture_sheet(entries: list[dict[str, Any]], output: Path) -> None:
    wanted = [
        ("start_day", "Start · day"),
        ("start_night_rain", "Start · night + rain"),
        ("boss_day", "Boss · day"),
        ("boss_night_rain", "Boss · night + rain"),
    ]
    by_fixture = {entry.get("fixture"): entry for entry in entries if entry.get("_actual_png_size") == (1920, 1080)}
    thumb = (640, 360)
    cell_w, cell_h = 660, 405
    margin, gap = 24, 18
    canvas = Image.new("RGB", (margin * 2 + cell_w * 2 + gap, margin * 2 + cell_h * 2 + gap), (22, 22, 26))
    draw = ImageDraw.Draw(canvas)
    title_font = _font(22)
    label_font = _font(18)
    for index, (fixture, label) in enumerate(wanted):
        x = margin + (index % 2) * (cell_w + gap)
        y = margin + (index // 2) * (cell_h + gap)
        draw.text((x, y), label, fill=(236, 236, 240), font=title_font)
        entry = by_fixture.get(fixture)
        image = None
        if entry and isinstance(entry.get("_path"), Path):
            try:
                image = Image.open(entry["_path"]).convert("RGB")
            except OSError:
                image = None
        if image is None:
            draw.rectangle((x, y + 34, x + thumb[0], y + 34 + thumb[1]), fill=(5, 5, 7), outline=(180, 70, 70))
            draw.text((x + 12, y + 50), "missing 1920×1080 fixture", fill=(230, 130, 130), font=label_font)
        else:
            canvas.paste(_fit_image(image, thumb, background=(5, 5, 7)), (x, y + 34))
            draw.rectangle((x, y + 34, x + thumb[0] - 1, y + 34 + thumb[1] - 1), outline=(108, 108, 120))
            image.close()
    canvas.save(output, format="PNG", optimize=True)


def _make_resolution_sheet(entries: list[dict[str, Any]], output: Path) -> None:
    selected = [entry for entry in entries if entry.get("fixture") == "start_night_rain"]
    selected.sort(key=lambda entry: _as_size(entry.get("requested")) or (0, 0))
    cols = 4
    rows = max(1, math.ceil(len(selected) / cols))
    thumb = (320, 180)
    cell_w, cell_h = 350, 222
    margin, gap = 20, 16
    canvas = Image.new("RGB", (margin * 2 + cols * cell_w + (cols - 1) * gap, margin * 2 + rows * cell_h + (rows - 1) * gap), (22, 22, 26))
    draw = ImageDraw.Draw(canvas)
    title_font = _font(17)
    detail_font = _font(14)
    for index, entry in enumerate(selected):
        x = margin + (index % cols) * (cell_w + gap)
        y = margin + (index // cols) * (cell_h + gap)
        requested = _fmt_size(entry.get("requested"))
        actual = _fmt_size(entry.get("_actual_png_size"))
        draw.text((x, y), requested, fill=(236, 236, 240), font=title_font)
        draw.text((x + 120, y + 2), f"PNG {actual}", fill=(170, 170, 180), font=detail_font)
        image = None
        if isinstance(entry.get("_path"), Path):
            try:
                image = Image.open(entry["_path"]).convert("RGB")
            except OSError:
                image = None
        if image is None:
            draw.rectangle((x, y + 28, x + thumb[0], y + 28 + thumb[1]), fill=(5, 5, 7), outline=(180, 70, 70))
            draw.text((x + 10, y + 45), "missing fixture", fill=(230, 130, 130), font=detail_font)
        else:
            canvas.paste(_fit_image(image, thumb, background=(5, 5, 7)), (x, y + 28))
            draw.rectangle((x, y + 28, x + thumb[0] - 1, y + 28 + thumb[1] - 1), outline=(108, 108, 120))
            image.close()
    canvas.save(output, format="PNG", optimize=True)


def _make_location_sheet(entries: list[dict[str, Any]], output: Path) -> None:
    """Make the supplement's fixed location/weather matrix.

    Placement is driven solely by the renderer's ``fixture`` field.  The PNG
    filename is only used to open the file, so an unknown or renamed weather
    capture cannot silently be interpreted from its spelling.
    """

    locations = ("start", "pit", "east", "boss", "forge")
    weather = ("day", "night_rain", "fog")
    by_fixture: dict[str, dict[str, Any]] = {}
    for entry in entries:
        fixture = entry.get("fixture")
        if isinstance(fixture, str) and fixture in {f"{location}_{state}" for location in locations for state in weather}:
            if entry.get("_actual_png_size") == (1920, 1080):
                by_fixture[fixture] = entry

    thumb = (320, 180)
    cols, rows = len(weather), len(locations)
    cell_w, cell_h = 350, 222
    margin, gap = 24, 18
    canvas = Image.new(
        "RGB",
        (margin * 2 + cols * cell_w + (cols - 1) * gap, margin * 2 + rows * cell_h + (rows - 1) * gap),
        (22, 22, 26),
    )
    draw = ImageDraw.Draw(canvas)
    header_font = _font(17)
    detail_font = _font(13)
    for row, location in enumerate(locations):
        for col, state in enumerate(weather):
            fixture = f"{location}_{state}"
            x = margin + col * (cell_w + gap)
            y = margin + row * (cell_h + gap)
            draw.text((x, y), f"{location} · {state}", fill=(236, 236, 240), font=header_font)
            entry = by_fixture.get(fixture)
            image = None
            if entry and isinstance(entry.get("_path"), Path):
                try:
                    image = Image.open(entry["_path"]).convert("RGB")
                except OSError:
                    image = None
            if image is None:
                draw.rectangle((x, y + 28, x + thumb[0], y + 28 + thumb[1]), fill=(5, 5, 7), outline=(180, 70, 70))
                draw.text((x + 10, y + 45), "missing fixture", fill=(230, 130, 130), font=detail_font)
            else:
                canvas.paste(_fit_image(image, thumb, background=(5, 5, 7)), (x, y + 28))
                draw.rectangle((x, y + 28, x + thumb[0] - 1, y + 28 + thumb[1] - 1), outline=(108, 108, 120))
                image.close()
    canvas.save(output, format="PNG", optimize=True)


def _markdown_report(
    data: dict[str, Any],
    entries: list[dict[str, Any]],
    title_entries: list[dict[str, Any]],
    issues: list[str],
    output: Path,
    sheet_names: tuple[str, str],
    supplement_sheet: str | None = None,
) -> None:
    errors = [str(item) for item in data.get("errors", []) if item]
    exit_errors = [str(item) for item in data.get("engine_exit_errors", []) if item]
    failed = bool(issues or errors or exit_errors or data.get("passed") is False)
    lines = [
        "# Display acceptance report",
        "",
        f"Generated: `{datetime.now(timezone.utc).isoformat(timespec='seconds')}`",
        "",
        f"**Result:** {'FAIL' if failed else 'PASS (fixture checks)'}",
        "",
        "This is a native root render-target capture run for display validation. The fixtures teleport/freeze actors and override clock/weather state; they are **not** a playthrough and do not prove that either ending is completable.",
        "",
        "## Run metadata",
        "",
        f"- Capture: {_safe_name(data.get('capture_type', '—'))}",
        f"- Purpose: {_safe_name(data.get('purpose', '—'))}",
        f"- Renderer: `{_safe_name(data.get('renderer', '—'))}` / driver `{_safe_name(data.get('driver', '—'))}`",
        f"- GPU: {_safe_name(data.get('gpu', '—'))} ({_safe_name(data.get('gpu_vendor', '—'))})",
        f"- Display server: {_safe_name(data.get('display_server', '—'))}; vsync: {_safe_name(data.get('vsync', '—'))}",
        f"- Screen at capture host: `{_fmt_size(data.get('screen_size'))}`",
        "",
        "## Fixture captures",
        "",
        "| Fixture | Requested/window | PNG dimensions | World scale | Content rect | HUD rect | World image rect | Status |",
        "| --- | ---: | ---: | ---: | --- | --- | --- | --- |",
    ]
    for entry in entries:
        requested = _fmt_size(entry.get("requested") or entry.get("window_size"))
        actual = _fmt_size(entry.get("_actual_png_size"))
        expected = _as_size(entry.get("requested"))
        png_actual = entry.get("_actual_png_size")
        row_failed = bool(entry.get("passed") is False)
        if not entry.get("_path"):
            row_failed = True
        lines.append(
            "| "
            + " | ".join(
                [
                    _safe_name(entry.get("fixture", "—")),
                    requested,
                    actual,
                    _safe_name(entry.get("world_scale", "—")),
                    _fmt_rect(entry.get("physical_content_rect")),
                    _fmt_rect(entry.get("actual_hud_root_rect")),
                    _fmt_rect(entry.get("actual_world_image_rect")),
                    "FAIL" if row_failed else "ok",
                ]
            )
            + " |"
        )
    lines.extend(
        [
            "",
            "Each PNG dimension above is read from the image file itself. Any stale or rounded JSON dimension is reported as an issue below.",
            "",
        ]
    )
    if title_entries:
        lines.extend(
            [
                "## Title screen bounds",
                "",
                "Title captures use the same native root render target. The bounds below are measured in physical pixels after the root transform.",
                "",
                "| Requested | PNG dimensions | Actual title rect | Physical content rect | Status |",
                "| ---: | ---: | --- | --- | --- |",
            ]
        )
        for entry in title_entries:
            passed = bool(entry.get("passed", True)) and bool(entry.get("_path"))
            lines.append(
                "| "
                + " | ".join(
                    [
                        _fmt_size(entry.get("requested")),
                        _fmt_size(entry.get("_actual_png_size")),
                        _fmt_rect(entry.get("actual_title_rect")),
                        _fmt_rect(entry.get("physical_content_rect")),
                        "ok" if passed else "FAIL",
                    ]
                )
                + " |"
            )
        lines.extend(["", f"Title bounds passing: {sum(bool(entry.get('passed', True)) and bool(entry.get('_path')) for entry in title_entries)}/{len(title_entries)}.", ""])
    lines.extend(
        [
            "## Timing sample",
            "",
            "Timing values are wall-frame measurements with warmup/loading and PNG encoding excluded. They include CPU scheduling, driver, and compositor effects and are **not isolated GPU timings**.",
            "",
            "| Resolution | Fixture | Samples | Warmup | Mean | Median | P95 | Max |",
            "| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    timings = data.get("timings", [])
    if isinstance(timings, list):
        for timing in timings:
            if not isinstance(timing, dict):
                continue
            lines.append(
                "| "
                + " | ".join(
                    [
                        _fmt_size(timing.get("requested")),
                        _safe_name(timing.get("fixture", "—")),
                        _safe_name(timing.get("samples", "—")),
                        _safe_name(timing.get("warmup_frames", "—")),
                        f"{float(timing['wall_frame_mean_ms']):.3f} ms" if isinstance(timing.get("wall_frame_mean_ms"), (int, float)) else "—",
                        f"{float(timing['wall_frame_median_ms']):.3f} ms" if isinstance(timing.get("wall_frame_median_ms"), (int, float)) else "—",
                        f"{float(timing['wall_frame_p95_ms']):.3f} ms" if isinstance(timing.get("wall_frame_p95_ms"), (int, float)) else "—",
                        f"{float(timing['wall_frame_max_ms']):.3f} ms" if isinstance(timing.get("wall_frame_max_ms"), (int, float)) else "—",
                    ]
                )
                + " |"
            )
    wing = data.get("wing_animation", {})
    if isinstance(wing, dict) and wing:
        lines.extend(["", "## Wing animation", "", f"Frame-change check: {'passed' if wing.get('passed') else 'FAILED'}. The actor stays in the same fixture position while its ordinary animation process advances; this is not a combat test.", ""])
        for frame in wing.get("frames", []):
            lines.append(f"- [{_safe_name(frame.get('png'))}]({frame.get('png')}): `{_safe_name(frame.get('texture'))}` at {frame.get('wall_ms')} ms")
    lines.extend(["", "## Review sheets", "", f"- [1080p fixture comparison]({sheet_names[0]})", f"- [Start night + rain across resolutions]({sheet_names[1]})"])
    if supplement_sheet:
        lines.extend(
            [
                f"- [Supplement location/weather matrix]({supplement_sheet})",
                "",
                "The supplement matrix places cells from the JSON `fixture` field (`start_day`, `pit_night_rain`, and so on). Weather labels are schema labels; unknown weather scenes are not inferred from PNG filenames.",
            ]
        )
    lines.append("")
    if errors or exit_errors or issues:
        lines.extend(["## Validation issues", ""])
        for issue in [*issues, *errors, *exit_errors]:
            lines.append(f"- `{_safe_name(issue)}`")
        lines.append("")
    else:
        lines.extend(["## Validation issues", "", "No image-dimension, renderer-reported, or shutdown errors were present in the input report.", ""])
    lines.extend(
        [
            "## Scope limits",
            "",
            "The renderer positions the window offscreen and captures the native root render target; these are not desktop screenshots. It uses fixture teleportation, frozen actors, and fixed time/weather to make display states reproducible. A passing report only supports the measured display/layout claims. Gameplay input, combat, save/load, progression, and ending completion still require the real-input acceptance path.",
            "",
        ]
    )
    output.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT, help="Path to render_acceptance report.json")
    parser.add_argument("--output-dir", type=Path, help="Directory for report.md and PNG sheets (defaults to report directory)")
    args = parser.parse_args()
    report_path = args.report.resolve()
    output_dir = (args.output_dir or report_path.parent).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    data = json.loads(report_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("report JSON must contain an object")
    entries, issues = _load_entries(data, report_path.parent)
    title_entries, title_issues = _load_title_entries(data, report_path.parent)
    issues.extend(title_issues)
    sheet_1080 = output_dir / "comparison_1080p_2x2.png"
    sheet_resolutions = output_dir / "comparison_start_night_rain_resolutions.png"
    _make_fixture_sheet(entries, sheet_1080)
    _make_resolution_sheet(entries, sheet_resolutions)
    supplement_sheet: Path | None = None
    if data.get("supplement") is True:
        supplement_sheet = output_dir / "comparison_locations.png"
        _make_location_sheet(entries, supplement_sheet)
    report_md = output_dir / "report.md"
    _markdown_report(
        data,
        entries,
        title_entries,
        issues,
        report_md,
        (sheet_1080.name, sheet_resolutions.name),
        supplement_sheet.name if supplement_sheet else None,
    )
    print(f"Wrote {report_md}")
    with Image.open(sheet_1080) as image:
        print(f"Wrote {sheet_1080} ({image.width}×{image.height})")
    with Image.open(sheet_resolutions) as image:
        print(f"Wrote {sheet_resolutions} ({image.width}×{image.height})")
    if supplement_sheet:
        with Image.open(supplement_sheet) as image:
            print(f"Wrote {supplement_sheet} ({image.width}×{image.height})")
    if issues:
        print(f"Found {len(issues)} input issue(s); see report.md")
    return 1 if issues or not data.get("passed", False) else 0


if __name__ == "__main__":
    raise SystemExit(main())
