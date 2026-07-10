from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

from PIL import Image


FRAME_SIZE = 192
BASELINE_EXCLUSIVE = 138
EXPECTED_FRAMES = {
    "idle": 6, "run": 6, "attack_1": 6, "attack_2": 6,
    "cast": 6, "hit": 3, "death": 6, "dash": 4, "defend": 4,
}
CHARACTERS = ("warrior", "archer", "lancer", "mage")


def components(alpha: Image.Image) -> list[list[tuple[int, int]]]:
    seen: set[tuple[int, int]] = set()
    result: list[list[tuple[int, int]]] = []
    for y in range(alpha.height):
        for x in range(alpha.width):
            if alpha.getpixel((x, y)) == 0 or (x, y) in seen:
                continue
            group: list[tuple[int, int]] = []
            queue = deque([(x, y)])
            seen.add((x, y))
            while queue:
                px, py = queue.popleft()
                group.append((px, py))
                for point in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= point[0] < alpha.width and 0 <= point[1] < alpha.height and point not in seen and alpha.getpixel(point) > 0:
                        seen.add(point)
                        queue.append(point)
            result.append(group)
    return sorted(result, key=len, reverse=True)


def component_bounds(group: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [point[0] for point in group]
    ys = [point[1] for point in group]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def component_gap(first: tuple[int, int, int, int], second: tuple[int, int, int, int]) -> int:
    horizontal = max(0, first[0] - second[2], second[0] - first[2])
    vertical = max(0, first[1] - second[3], second[1] - first[3])
    return max(horizontal, vertical)


def component_pixel_gap(first: list[tuple[int, int]], second: list[tuple[int, int]]) -> int:
    closest = min(
        max(abs(first_x - second_x), abs(first_y - second_y))
        for first_x, first_y in first
        for second_x, second_y in second
    )
    return max(0, closest - 1)


def is_stray_component(size: int, gap: int) -> bool:
    return 8 < size <= 200 and gap >= 12


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    report: dict[str, dict] = {}
    for character in CHARACTERS:
        animation_dir = root / "assets" / "original" / "characters" / character / "animations"
        report[character] = {}
        for animation, frame_count in EXPECTED_FRAMES.items():
            path = animation_dir / f"{character}_{animation}.png"
            if not path.exists():
                errors.append(f"missing: {path}")
                continue
            image = Image.open(path).convert("RGBA")
            if image.size != (FRAME_SIZE * frame_count, FRAME_SIZE):
                errors.append(f"wrong size: {path} is {image.size}, expected {(FRAME_SIZE * frame_count, FRAME_SIZE)}")
                continue
            frame_report = []
            for index in range(frame_count):
                frame = image.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE))
                bounds = frame.getbbox()
                if bounds is None:
                    errors.append(f"empty frame: {path} frame {index}")
                    continue
                if bounds[3] != BASELINE_EXCLUSIVE:
                    errors.append(f"wrong baseline: {path} frame {index} ends at y={bounds[3]}, expected {BASELINE_EXCLUSIVE}")
                if bounds[0] <= 0 or bounds[2] >= FRAME_SIZE:
                    errors.append(f"clipped horizontal boundary: {path} frame {index} bounds={bounds}")
                alpha = frame.getchannel("A")
                partial_alpha = sum(1 for value in alpha.get_flattened_data() if value not in (0, 255))
                groups = components(alpha)
                tiny = [len(group) for group in groups[1:] if len(group) <= 8]
                if tiny:
                    errors.append(f"isolated alpha fragments: {path} frame {index} sizes={tiny}")
                if groups:
                    main_bounds = component_bounds(groups[0])
                    distant = []
                    for group in groups[1:]:
                        pixel_gap = component_pixel_gap(groups[0], group)
                        if is_stray_component(len(group), pixel_gap):
                            distant.append((len(group), component_bounds(group), pixel_gap))
                    if distant:
                        errors.append(f"distant alpha fragments: {path} frame {index} components={distant}")
                frame_report.append({
                    "frame": index, "bounds": bounds, "components": [len(group) for group in groups],
                    "partial_alpha_pixels": partial_alpha,
                })
            report[character][animation] = frame_report
        idle_centers = lower_body_centers(animation_dir / f"{character}_idle.png", 6)
        run_centers = lower_body_centers(animation_dir / f"{character}_run.png", 6)
        idle_anchor = sorted(idle_centers)[len(idle_centers) // 2]
        run_anchor = sorted(run_centers)[len(run_centers) // 2]
        if abs(idle_anchor - run_anchor) > 2.0:
            errors.append(f"idle/run anchor mismatch: {character} idle={idle_anchor:.2f} run={run_anchor:.2f}")
    (root / "tests" / "character_sprite_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return errors


def lower_body_centers(path: Path, frame_count: int) -> list[float]:
    image = Image.open(path).convert("RGBA")
    centers: list[float] = []
    for index in range(frame_count):
        alpha = image.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE)).getchannel("A")
        points = [(x, y) for y in range(96, BASELINE_EXCLUSIVE) for x in range(FRAME_SIZE) if alpha.getpixel((x, y)) > 0]
        centers.append(sum(x for x, _y in points) / len(points))
    return centers


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate original character sprite sheets.")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors = validate(args.root)
    if errors:
        print("FAIL: character sprite validation")
        for error in errors:
            print(f"- {error}")
        return 1
    print("PASS: character sprite validation")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
