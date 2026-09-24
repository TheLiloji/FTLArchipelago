#!/usr/bin/env python3

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "ArchipelagoFTL/img/weapons"

SOURCE_FILE = "ap_gift_filler_strip1.png"
OUTPUT_FILE = "ap_package_strip1.png"

PLUM = (0xAF, 0x99, 0xEF)
GRAY_THRESHOLD = 14
LUMINANCE_REF = 160


def tint() -> None:
    source = Image.open(IMG / SOURCE_FILE).convert("RGBA")
    px = source.load()
    out_img = Image.new("RGBA", source.size)
    sp = out_img.load()
    count = 0
    for y in range(source.size[1]):
        for x in range(source.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if max(r, g, b) - min(r, g, b) >= GRAY_THRESHOLD:
                sp[x, y] = (r, g, b, a)
                continue
            lum = (0.299 * r + 0.587 * g + 0.114 * b)
            f = lum / LUMINANCE_REF
            sp[x, y] = (min(255, round(PLUM[0] * f)),
                        min(255, round(PLUM[1] * f)),
                        min(255, round(PLUM[2] * f)), a)
            count += 1
    out_img.save(IMG / OUTPUT_FILE, optimize=True)
    print(f"{IMG / OUTPUT_FILE} ({count} pixels retinted out of {source.size[0] * source.size[1]})")


if __name__ == "__main__":
    if not (IMG / SOURCE_FILE).is_file():
        raise SystemExit(f"template not found: {IMG / SOURCE_FILE}")
    tint()
