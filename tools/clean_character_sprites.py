from __future__ import annotations

from pathlib import Path

from PIL import Image

from validate_character_sprites import CHARACTERS, EXPECTED_FRAMES, FRAME_SIZE, component_pixel_gap, components, is_stray_component, lower_body_centers


def clean_frame(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A")
    groups = components(alpha)
    if not groups:
        return frame
    pixels = frame.load()
    for group in groups[1:]:
        gap = component_pixel_gap(groups[0], group)
        if len(group) <= 8 or is_stray_component(len(group), gap):
            for x, y in group:
                pixels[x, y] = (0, 0, 0, 0)
    bounds = frame.getbbox()
    if bounds is None:
        return frame
    shift_x = 1 - bounds[0] if bounds[0] <= 0 else 190 - bounds[2] if bounds[2] >= FRAME_SIZE else 0
    shift_y = 138 - bounds[3]
    if shift_x or shift_y:
        shifted = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        shifted.alpha_composite(frame, (shift_x, shift_y))
        return shifted
    return frame


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for character in CHARACTERS:
        directory = root / "assets" / "original" / "characters" / character / "animations"
        for animation, frame_count in EXPECTED_FRAMES.items():
            path = directory / f"{character}_{animation}.png"
            image = Image.open(path).convert("RGBA")
            output = Image.new("RGBA", image.size, (0, 0, 0, 0))
            for index in range(frame_count):
                frame = image.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE))
                output.alpha_composite(clean_frame(frame), (index * FRAME_SIZE, 0))
            output.save(path)
        align_run_to_idle(directory, character)
    print("Cleaned character sprite sheets")


def align_run_to_idle(directory: Path, character: str) -> None:
    idle_path = directory / f"{character}_idle.png"
    run_path = directory / f"{character}_run.png"
    idle_centers = lower_body_centers(idle_path, 6)
    run_centers = lower_body_centers(run_path, 6)
    target = sorted(idle_centers)[len(idle_centers) // 2]
    source = sorted(run_centers)[len(run_centers) // 2]
    shift_x = round(target - source)
    if shift_x == 0:
        return
    run = Image.open(run_path).convert("RGBA")
    output = Image.new("RGBA", run.size, (0, 0, 0, 0))
    for index in range(6):
        frame = run.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE))
        output.alpha_composite(frame, (index * FRAME_SIZE + shift_x, 0))
    output.save(run_path)


if __name__ == "__main__":
    main()
