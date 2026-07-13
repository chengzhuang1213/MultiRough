from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


FRAME_SIZE = 192
BASELINE_Y = 138


def lower_body_center(frame: Image.Image) -> float:
    alpha = frame.getchannel("A")
    points = [(x, y) for y in range(96, BASELINE_Y) for x in range(FRAME_SIZE) if alpha.getpixel((x, y)) > 0]
    return sum(x for x, _y in points) / len(points) if points else FRAME_SIZE * 0.5


def normalize(source: Path, destination: Path, frame_count: int, scale_x: float, scale_y: float, anchor_x: float) -> None:
    sheet = Image.open(source).convert("RGBA")
    if sheet.size != (FRAME_SIZE * frame_count, FRAME_SIZE):
        raise ValueError(f"unexpected sheet size: {sheet.size}")
    output = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    for index in range(frame_count):
        frame = sheet.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE))
        bounds = frame.getbbox()
        if bounds is None:
            raise ValueError(f"empty frame: {index}")
        subject = frame.crop(bounds)
        size = (max(1, round(subject.width * scale_x)), max(1, round(subject.height * scale_y)))
        subject = subject.resize(size, Image.Resampling.NEAREST)
        temporary = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        temporary.alpha_composite(subject, ((FRAME_SIZE - subject.width) // 2, BASELINE_Y - subject.height))
        shift_x = round(anchor_x - lower_body_center(temporary))
        output.alpha_composite(temporary, (index * FRAME_SIZE + shift_x, 0))
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination)


def main() -> None:
    parser = argparse.ArgumentParser(description="Apply one scale and lower-body anchor to a sprite sheet.")
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("frame_count", type=int)
    parser.add_argument("--scale", type=float, default=1.0)
    parser.add_argument("--scale-x", type=float, default=1.0)
    parser.add_argument("--scale-y", type=float, default=1.0)
    parser.add_argument("--anchor-x", type=float, required=True)
    args = parser.parse_args()
    normalize(
        args.source,
        args.destination,
        args.frame_count,
        args.scale * args.scale_x,
        args.scale * args.scale_y,
        args.anchor_x,
    )


if __name__ == "__main__":
    main()
