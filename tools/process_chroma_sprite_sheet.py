from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


FRAME_SIZE = 192
BASELINE_Y = 138
MAX_CHARACTER_HEIGHT = 128
MAX_CHARACTER_WIDTH = 180


def lower_body_centroid_x(frame: Image.Image) -> float:
    alpha = frame.getchannel("A")
    weighted_x = 0
    weight = 0
    for y in range(96, FRAME_SIZE):
        for x in range(FRAME_SIZE):
            value = alpha.getpixel((x, y))
            weighted_x += x * value
            weight += value
    return weighted_x / weight if weight else FRAME_SIZE / 2


def align_lower_body(sheet: Image.Image, frame_count: int) -> Image.Image:
    frames = [sheet.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE)) for index in range(frame_count)]
    anchors = [lower_body_centroid_x(frame) for frame in frames]
    target = sorted(anchors)[len(anchors) // 2]
    aligned = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    for index, (frame, anchor) in enumerate(zip(frames, anchors)):
        shift_x = round(target - anchor)
        aligned.alpha_composite(frame, (index * FRAME_SIZE + shift_x, 0))
    return aligned


def remove_chroma(image: Image.Image, key_color: str) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, _alpha = pixels[x, y]
            is_key = green > 120 and green > red * 1.28 and green > blue * 1.28
            if key_color == "magenta":
                is_key = red > 120 and blue > 120 and red > green * 1.28 and blue > green * 1.28
            if is_key:
                pixels[x, y] = (red, green, blue, 0)
    return rgba


def remove_green(image: Image.Image) -> Image.Image:
    return remove_chroma(image, "green")


def keep_largest_component(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(image.height):
        for x in range(image.width):
            if alpha.getpixel((x, y)) == 0 or (x, y) in seen:
                continue
            component: list[tuple[int, int]] = []
            stack = [(x, y)]
            seen.add((x, y))
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < image.width and 0 <= ny < image.height and (nx, ny) not in seen and alpha.getpixel((nx, ny)) > 0:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            components.append(component)
    if len(components) <= 1:
        return image
    largest = max(components, key=len)
    cleaned = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source = image.load()
    target = cleaned.load()
    for x, y in largest:
        target[x, y] = source[x, y]
    return cleaned


def keep_main_and_nearby_equipment(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(image.height):
        for x in range(image.width):
            if alpha.getpixel((x, y)) == 0 or (x, y) in seen:
                continue
            component: list[tuple[int, int]] = []
            stack = [(x, y)]
            seen.add((x, y))
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < image.width and 0 <= ny < image.height and (nx, ny) not in seen and alpha.getpixel((nx, ny)) > 0:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            components.append(component)
    if not components:
        return image
    main = max(components, key=len)
    main_x = [point[0] for point in main]
    main_y = [point[1] for point in main]
    main_box = (min(main_x), min(main_y), max(main_x) + 1, max(main_y) + 1)
    kept = [main]
    for component in components:
        if component is main or len(component) < 500:
            continue
        xs = [point[0] for point in component]
        ys = [point[1] for point in component]
        box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        horizontal_gap = max(0, main_box[0] - box[2], box[0] - main_box[2])
        vertical_gap = max(0, main_box[1] - box[3], box[1] - main_box[3])
        if horizontal_gap <= 8 and vertical_gap <= 8:
            kept.append(component)
    cleaned = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source = image.load()
    target = cleaned.load()
    for component in kept:
        for x, y in component:
            target[x, y] = source[x, y]
    return cleaned


def process(source: Path, destination: Path, frame_count: int, keep_largest: bool, keep_nearby: bool, uniform_transform: bool, align_lower: bool, key_color: str) -> None:
    source_image = remove_chroma(Image.open(source), key_color)
    output = Image.new("RGBA", (FRAME_SIZE * frame_count, FRAME_SIZE), (0, 0, 0, 0))
    source_cell_width = source_image.width / frame_count
    subjects: list[Image.Image] = []
    for index in range(frame_count):
        left = round(index * source_cell_width)
        right = round((index + 1) * source_cell_width)
        cell = source_image.crop((left, 0, right, source_image.height))
        if keep_largest:
            cell = keep_largest_component(cell)
        elif keep_nearby:
            cell = keep_main_and_nearby_equipment(cell)
        bounds = cell.getbbox()
        if bounds is None:
            subjects.append(Image.new("RGBA", (1, 1), (0, 0, 0, 0)))
        else:
            subjects.append(cell.crop(bounds))

    common_scale = min(
        MAX_CHARACTER_WIDTH / max(subject.width for subject in subjects),
        MAX_CHARACTER_HEIGHT / max(subject.height for subject in subjects),
    )
    for index, subject in enumerate(subjects):
        scale = common_scale if uniform_transform else min(MAX_CHARACTER_WIDTH / subject.width, MAX_CHARACTER_HEIGHT / subject.height)
        size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
        subject = subject.resize(size, Image.Resampling.NEAREST)
        x = index * FRAME_SIZE + (FRAME_SIZE - subject.width) // 2
        y = BASELINE_Y - subject.height
        output.alpha_composite(subject, (x, y))

    if align_lower:
        output = align_lower_body(output, frame_count)
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("frame_count", type=int)
    parser.add_argument("--keep-largest", action="store_true")
    parser.add_argument("--keep-nearby-equipment", action="store_true")
    parser.add_argument("--uniform-transform", action="store_true")
    parser.add_argument("--align-lower-body", action="store_true")
    parser.add_argument("--key-color", choices=("green", "magenta"), default="green")
    args = parser.parse_args()
    process(args.source, args.destination, args.frame_count, args.keep_largest, args.keep_nearby_equipment, args.uniform_transform, args.align_lower_body, args.key_color)


if __name__ == "__main__":
    main()
