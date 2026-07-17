from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description="Crop and resize generated UI panels.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("width", type=int)
    parser.add_argument("height", type=int)
    args = parser.parse_args()

    image = Image.open(args.input).convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels in {args.input}")

    cropped = image.crop(bounds)
    resized = cropped.resize((args.width, args.height), Image.Resampling.LANCZOS)
    pixels = resized.load()
    for y in range(resized.height):
        for x in range(resized.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 0 and red > 220 and blue > 220 and green < 60:
                pixels[x, y] = (red, green, blue, 0)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    resized.save(args.output, optimize=True)


if __name__ == "__main__":
    main()
