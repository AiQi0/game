#!/usr/bin/env python3
"""Rebuild medieval pixel assets from the original generated atlases.

The output pass intentionally avoids any added outline stroke. It chroma-keys
the original magenta atlas background, trims residual exterior fringe pixels,
snaps alpha to hard pixel-art transparency, quantizes color, and places each
asset on the manifest-defined canvas size.
"""

from __future__ import annotations

import json
import argparse
import shutil
from collections import deque
from datetime import datetime
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image


SOURCE_PACK = Path("assets/medieval_pixel_pack_v2")
OUTPUT_PACK = Path("assets/medieval_pixel_pack_v3_no_outline")
PACK_ID = "medieval_pixel_pack_v3_no_outline"
TRANSPARENT = (0, 0, 0, 0)


def load_manifest() -> dict[str, Any]:
    return json.loads((SOURCE_PACK / "asset_manifest.json").read_text(encoding="utf-8"))


def build_sheet_grids(assets: list[dict[str, Any]]) -> dict[str, tuple[int, int]]:
    grids: dict[str, tuple[int, int]] = {}
    for asset in assets:
        source_sheet = asset["source_sheet"]
        row = int(asset["source_cell"]["row"])
        col = int(asset["source_cell"]["col"])
        rows, cols = grids.get(source_sheet, (0, 0))
        grids[source_sheet] = (max(rows, row), max(cols, col))
    return grids


def magenta_like(rgb_or_rgba: np.ndarray) -> np.ndarray:
    r = rgb_or_rgba[..., 0].astype(np.int16)
    g = rgb_or_rgba[..., 1].astype(np.int16)
    b = rgb_or_rgba[..., 2].astype(np.int16)
    return (
        (r > 170)
        & (b > 170)
        & (g < 110)
        & (((r + b) // 2 - g) > 80)
        & (np.abs(r - b) < 90)
    )


def flood_chroma_to_alpha(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    height, width = arr.shape[:2]
    candidates = magenta_like(arr)
    background = np.zeros((height, width), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        if candidates[y, x] and not background[y, x]:
            background[y, x] = True
            queue.append((x, y))

    for x in range(width):
        push(x, 0)
        push(x, height - 1)
    for y in range(height):
        push(0, y)
        push(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                push(nx, ny)

    arr[background, 3] = 0
    return Image.fromarray(arr, "RGBA")


def alpha_bbox(image: Image.Image, threshold: int = 20) -> tuple[int, int, int, int] | None:
    alpha = np.array(image.convert("RGBA"))[..., 3]
    ys, xs = np.where(alpha > threshold)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def hard_alpha(image: Image.Image, threshold: int = 36) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[..., 3] = np.where(arr[..., 3] > threshold, 255, 0).astype(np.uint8)
    arr[arr[..., 3] == 0, :3] = 0
    return Image.fromarray(arr, "RGBA")


def shave_exterior_fringe(image: Image.Image) -> Image.Image:
    """Remove a single exterior fringe pixel when it reads as stroke residue."""
    arr = np.array(image.convert("RGBA"))
    mask = arr[..., 3] > 0
    height, width = mask.shape
    edge = np.zeros_like(mask, dtype=bool)

    for y in range(height):
        for x in range(width):
            if not mask[y, x]:
                continue
            x0 = max(0, x - 1)
            x1 = min(width, x + 2)
            y0 = max(0, y - 1)
            y1 = min(height, y + 2)
            if np.any(~mask[y0:y1, x0:x1]):
                edge[y, x] = True

    r = arr[..., 0].astype(np.int16)
    g = arr[..., 1].astype(np.int16)
    b = arr[..., 2].astype(np.int16)
    luminance = (r * 299 + g * 587 + b * 114) // 1000
    magenta_fringe = (r > 80) & (b > 80) & (g < 105) & (((r + b) // 2 - g) > 55)
    dark_fringe = luminance < 38
    remove = edge & (magenta_fringe | dark_fringe)
    arr[remove] = TRANSPARENT
    return Image.fromarray(arr, "RGBA")


def drop_visible_magenta(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    remove = (arr[..., 3] > 0) & magenta_like(arr)
    arr[remove] = TRANSPARENT
    return Image.fromarray(arr, "RGBA")


def quantize_rgba(image: Image.Image, colors: int) -> Image.Image:
    image = image.convert("RGBA")
    alpha = np.array(image)[..., 3]
    quantized = image.quantize(
        colors=colors,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE,
    ).convert("RGBA")
    arr = np.array(quantized)
    arr[..., 3] = alpha
    arr[arr[..., 3] == 0, :3] = 0
    return Image.fromarray(arr, "RGBA")


def remove_tiny_components(image: Image.Image, min_area: int) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    mask = arr[..., 3] > 0
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    pixels_to_remove: list[tuple[int, int]] = []

    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            component: list[tuple[int, int]] = []
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y, x] = True
            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx in range(cx - 1, cx + 2):
                    for ny in range(cy - 1, cy + 2):
                        if nx == cx and ny == cy:
                            continue
                        if 0 <= nx < width and 0 <= ny < height:
                            if mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                queue.append((nx, ny))
            if len(component) < min_area:
                pixels_to_remove.extend(component)

    for x, y in pixels_to_remove:
        arr[y, x] = TRANSPARENT
    return Image.fromarray(arr, "RGBA")


def color_budget(category: str) -> int:
    if category == "buildings":
        return 64
    if category == "environment":
        return 48
    return 32


def pixel_padding(category: str, target_size: tuple[int, int]) -> int:
    if category == "buildings":
        return 0
    if target_size[0] <= 96:
        return 2
    return 1


def align_bottom(category: str) -> bool:
    return category in {"buildings", "npcs", "environment"}


def process_asset(
    asset: dict[str, Any],
    grids: dict[str, tuple[int, int]],
    sheet_cache: dict[str, Image.Image],
) -> tuple[Image.Image, dict[str, Any]]:
    source_sheet = asset["source_sheet"]
    sheet = sheet_cache.setdefault(source_sheet, Image.open(source_sheet).convert("RGBA"))
    rows, cols = grids[source_sheet]
    cell_width = sheet.width // cols
    cell_height = sheet.height // rows
    row = int(asset["source_cell"]["row"])
    col = int(asset["source_cell"]["col"])
    cell_box = (
        (col - 1) * cell_width,
        (row - 1) * cell_height,
        col * cell_width,
        row * cell_height,
    )

    cell = sheet.crop(cell_box)
    cleaned = flood_chroma_to_alpha(cell)
    source_bbox = alpha_bbox(cleaned)
    if source_bbox is None:
        raise RuntimeError(f"{asset['slug']} has no visible pixels after chroma key")

    crop = cleaned.crop(source_bbox)
    target_size = (int(asset["size"]["width"]), int(asset["size"]["height"]))
    padding = pixel_padding(asset["category"], target_size)
    max_width = max(1, target_size[0] - padding * 2)
    max_height = max(1, target_size[1] - padding * 2)
    scale = min(max_width / crop.width, max_height / crop.height)
    resized_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
    resample = Image.Resampling.BOX if scale < 1.0 else Image.Resampling.NEAREST
    resized = crop.resize(resized_size, resample)

    canvas = Image.new("RGBA", target_size, TRANSPARENT)
    x = (target_size[0] - resized_size[0]) // 2
    if align_bottom(asset["category"]):
        y = target_size[1] - resized_size[1] - padding
    else:
        y = (target_size[1] - resized_size[1]) // 2
    canvas.alpha_composite(resized, (x, y))

    canvas = hard_alpha(canvas)
    canvas = shave_exterior_fringe(canvas)
    canvas = hard_alpha(canvas)
    canvas = quantize_rgba(canvas, color_budget(asset["category"]))
    canvas = drop_visible_magenta(canvas)
    canvas = shave_exterior_fringe(canvas)
    canvas = hard_alpha(canvas)
    min_component_area = 8 if asset["category"] == "buildings" else 3
    canvas = remove_tiny_components(canvas, min_component_area)

    final_bbox = alpha_bbox(canvas)
    metadata = {
        "source_cell_box": list(cell_box),
        "source_bbox_after_chroma": list(source_bbox),
        "target_size": list(target_size),
        "resized_subject_size": list(resized_size),
        "placement": [x, y],
        "scale": scale,
        "final_bbox": list(final_bbox) if final_bbox else None,
        "color_budget": color_budget(asset["category"]),
        "added_outline": False,
        "exterior_fringe_trim": True,
    }
    return canvas, metadata


def process_single_raw_asset(asset: dict[str, Any], source_path: Path) -> tuple[Image.Image, dict[str, Any]]:
    raw = Image.open(source_path).convert("RGBA")
    cleaned = flood_chroma_to_alpha(raw)
    source_bbox = alpha_bbox(cleaned)
    if source_bbox is None:
        raise RuntimeError(f"{asset['slug']} replacement has no visible pixels after chroma key")

    crop = cleaned.crop(source_bbox)
    target_size = (int(asset["size"]["width"]), int(asset["size"]["height"]))
    padding = pixel_padding(asset["category"], target_size)
    max_width = max(1, target_size[0] - padding * 2)
    max_height = max(1, target_size[1] - padding * 2)
    scale = min(max_width / crop.width, max_height / crop.height)
    resized_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
    resample = Image.Resampling.BOX if scale < 1.0 else Image.Resampling.NEAREST
    resized = crop.resize(resized_size, resample)

    canvas = Image.new("RGBA", target_size, TRANSPARENT)
    x = (target_size[0] - resized_size[0]) // 2
    if align_bottom(asset["category"]):
        y = target_size[1] - resized_size[1] - padding
    else:
        y = (target_size[1] - resized_size[1]) // 2
    canvas.alpha_composite(resized, (x, y))

    canvas = hard_alpha(canvas)
    canvas = shave_exterior_fringe(canvas)
    canvas = hard_alpha(canvas)
    canvas = quantize_rgba(canvas, color_budget(asset["category"]))
    canvas = drop_visible_magenta(canvas)
    canvas = shave_exterior_fringe(canvas)
    canvas = hard_alpha(canvas)
    min_component_area = 8 if asset["category"] == "buildings" else 3
    canvas = remove_tiny_components(canvas, min_component_area)

    final_bbox = alpha_bbox(canvas)
    metadata = {
        "source_file": source_path.as_posix(),
        "source_bbox_after_chroma": list(source_bbox),
        "target_size": list(target_size),
        "resized_subject_size": list(resized_size),
        "placement": [x, y],
        "scale": scale,
        "final_bbox": list(final_bbox) if final_bbox else None,
        "color_budget": color_budget(asset["category"]),
        "added_outline": False,
        "exterior_fringe_trim": True,
        "single_asset_regeneration": True,
    }
    return canvas, metadata


def validate_png(path: Path, expected_size: tuple[int, int]) -> dict[str, Any]:
    image = Image.open(path).convert("RGBA")
    arr = np.array(image)
    alpha = arr[..., 3]
    unique_alpha = sorted(int(v) for v in np.unique(alpha))
    opaque = int(np.count_nonzero(alpha == 255))
    transparent = int(np.count_nonzero(alpha == 0))
    partial_alpha = int(np.count_nonzero((alpha > 0) & (alpha < 255)))
    visible_colors = np.unique(arr[alpha > 0, :3].reshape(-1, 3), axis=0) if opaque else []
    bbox = alpha_bbox(image)
    edge_magenta = 0
    if bbox:
        mask = alpha > 0
        height, width = mask.shape
        edge = np.zeros_like(mask, dtype=bool)
        for y in range(height):
            for x in range(width):
                if not mask[y, x]:
                    continue
                x0 = max(0, x - 1)
                x1 = min(width, x + 2)
                y0 = max(0, y - 1)
                y1 = min(height, y + 2)
                if np.any(~mask[y0:y1, x0:x1]):
                    edge[y, x] = True
        edge_magenta = int(np.count_nonzero(edge & magenta_like(arr)))
    return {
        "path": path.as_posix(),
        "size": list(image.size),
        "expected_size": list(expected_size),
        "size_ok": image.size == expected_size,
        "visible_pixels": opaque,
        "transparent_pixels": transparent,
        "partial_alpha_pixels": partial_alpha,
        "unique_alpha": unique_alpha,
        "unique_visible_colors": int(len(visible_colors)),
        "final_bbox": list(bbox) if bbox else None,
        "edge_magenta_pixels": edge_magenta,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--replace-slug", default="", help="Asset slug to replace from a single generated raw image.")
    parser.add_argument("--replacement-raw", type=Path, help="Single raw PNG used for --replace-slug.")
    parser.add_argument(
        "--replacement-raw-name",
        default="",
        help="Filename to store the replacement raw under the output _raw directory.",
    )
    return parser.parse_args()


def existing_single_replacements() -> dict[str, Path]:
    manifest_path = OUTPUT_PACK / "asset_manifest.json"
    if not manifest_path.exists():
        return {}
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    replacements: dict[str, Path] = {}
    for asset in manifest.get("assets", []):
        if asset.get("source_pack") != "single_image_gen_replacement":
            continue
        source_sheet = Path(str(asset.get("source_sheet", "")))
        if not source_sheet.exists():
            continue
        replacements[str(asset.get("slug", ""))] = source_sheet
    return replacements


def main() -> None:
    args = parse_args()
    replacement_slug = str(args.replace_slug).strip()
    if replacement_slug != "" and args.replacement_raw is None:
        raise SystemExit("--replacement-raw is required when --replace-slug is used")
    if args.replacement_raw is not None and not args.replacement_raw.exists():
        raise SystemExit(f"replacement raw does not exist: {args.replacement_raw}")

    manifest = load_manifest()
    assets = manifest["assets"]
    grids = build_sheet_grids(assets)
    OUTPUT_PACK.mkdir(parents=True, exist_ok=True)
    for subdir in ("_raw", "buildings", "npcs", "tools", "environment", "ui"):
        (OUTPUT_PACK / subdir).mkdir(parents=True, exist_ok=True)

    for raw_path in sorted((SOURCE_PACK / "_raw").glob("*.png")):
        shutil.copy2(raw_path, OUTPUT_PACK / "_raw" / raw_path.name)

    replacement_sources = existing_single_replacements()
    if replacement_slug != "":
        raw_name = args.replacement_raw_name.strip()
        if raw_name == "":
            raw_name = f"{replacement_slug}_regenerated_raw.png"
        replacement_sources[replacement_slug] = OUTPUT_PACK / "_raw" / raw_name
        shutil.copy2(args.replacement_raw, replacement_sources[replacement_slug])
    replacement_slugs = sorted(replacement_sources)

    sheet_cache: dict[str, Image.Image] = {}
    output_assets: list[dict[str, Any]] = []
    validation: list[dict[str, Any]] = []

    for asset in assets:
        asset_slug = str(asset["slug"])
        uses_replacement = asset_slug in replacement_sources
        if uses_replacement:
            image, process_meta = process_single_raw_asset(asset, replacement_sources[asset_slug])
        else:
            image, process_meta = process_asset(asset, grids, sheet_cache)
        output_path = OUTPUT_PACK / asset["category"] / Path(asset["file"]).name
        image.save(output_path)
        expected_size = (int(asset["size"]["width"]), int(asset["size"]["height"]))
        validation.append(validate_png(output_path, expected_size))

        next_asset = dict(asset)
        next_asset["file"] = output_path.as_posix()
        next_asset["source_pack"] = SOURCE_PACK.as_posix()
        if uses_replacement:
            next_asset["source_pack"] = "single_image_gen_replacement"
            next_asset["source_sheet"] = replacement_sources[asset_slug].as_posix()
            next_asset["source_cell"] = {
                "row": 1,
                "col": 1,
                "bbox_after_chroma": process_meta.get("source_bbox_after_chroma", []),
            }
            next_asset["regenerated_from_single_raw"] = True
        else:
            next_asset["source_sheet"] = (
                OUTPUT_PACK / "_raw" / Path(asset["source_sheet"]).name
            ).as_posix()
        next_asset["aseprite_pixel_pass"] = process_meta
        output_assets.append(next_asset)

    next_manifest = {
        "pack_id": PACK_ID,
        "status": "applied_aseprite_no_outline_pixel_redraw",
        "style": "medieval fairy-tale refined pixel art, no added outline stroke, transparent PNG",
        "source_pack": SOURCE_PACK.as_posix(),
        "source_generation": "assets/medieval_pixel_pack_v2/_raw original image_gen atlases",
        "single_asset_regenerations": replacement_slugs,
        "runtime_application": "applied through GameData.ART_ASSET_ROOT and scene texture references",
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "assets": output_assets,
    }
    (OUTPUT_PACK / "asset_manifest.json").write_text(
        json.dumps(next_manifest, indent=2),
        encoding="utf-8",
    )

    failures = [
        item
        for item in validation
        if (
            not item["size_ok"]
            or item["visible_pixels"] <= 0
            or item["transparent_pixels"] <= 0
            or item["partial_alpha_pixels"] != 0
            or item["edge_magenta_pixels"] != 0
        )
    ]
    report = {
        "pack_id": PACK_ID,
        "source_pack": SOURCE_PACK.as_posix(),
        "asset_count": len(validation),
        "failure_count": len(failures),
        "rules": {
            "uses_original_generated_raw_atlases": True,
            "uses_single_generated_raw_replacements": len(replacement_slugs) > 0,
            "adds_outline_stroke": False,
            "hard_alpha_only": True,
            "manifest_sizes_preserved": True,
        },
        "single_asset_regenerations": replacement_slugs,
        "validation": validation,
        "failures": failures,
    }
    (OUTPUT_PACK / "validation_report.json").write_text(
        json.dumps(report, indent=2),
        encoding="utf-8",
    )

    lines = [
        f"pack_id: {PACK_ID}",
        f"source_pack: {SOURCE_PACK.as_posix()}",
        f"asset_count: {len(validation)}",
        f"failure_count: {len(failures)}",
        f"single_asset_regenerations: {', '.join(replacement_slugs) if replacement_slugs else 'none'}",
        "rules:",
        "  uses_original_generated_raw_atlases: true",
        f"  uses_single_generated_raw_replacements: {str(len(replacement_slugs) > 0).lower()}",
        "  adds_outline_stroke: false",
        "  hard_alpha_only: true",
        "  manifest_sizes_preserved: true",
        "",
    ]
    for item in validation:
        status = "PASS" if item not in failures else "FAIL"
        lines.append(
            "%s %s size=%s colors=%s visible=%s edge_magenta=%s"
            % (
                status,
                item["path"],
                item["size"],
                item["unique_visible_colors"],
                item["visible_pixels"],
                item["edge_magenta_pixels"],
            )
        )
    (OUTPUT_PACK / "validation_report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")

    if failures:
        raise SystemExit(f"{len(failures)} assets failed validation")


if __name__ == "__main__":
    main()
