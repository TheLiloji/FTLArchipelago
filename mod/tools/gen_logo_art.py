#!/usr/bin/env python3
"""Builds every in-game picture of the FTL Archipelago logo from mod/art/ftl_archipelago_logo.png.

The logo's system icons are cut out of the circles. The menu copy fills them with the night blue of
the HUD so it reads on any background; the small icons fill them with a darker shade of their
circle, since at that size the logo only reads as six coloured discs. The shop crates keep their own
art: the logo is too small to read inside them.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "ftl_archipelago_logo.png"
IMG = ROOT / "ArchipelagoFTL" / "img"

CIRCLES = (
    (128, 51, 49, (201, 118, 130)), (55, 78, 49, (238, 227, 145)), (200, 78, 50, (117, 194, 117)),
    (54, 162, 50, (118, 126, 189)), (202, 162, 50, (202, 148, 194)), (128, 206, 50, (217, 160, 125)),
)
BLACK = (12, 12, 16, 255)
NIGHT = (18, 22, 34, 255)


def filled(mode: str) -> Image.Image:
    logo = Image.open(SOURCE).convert("RGBA")
    px = logo.load()
    width, height = logo.size
    for y in range(height):
        for x in range(width):
            if px[x, y][3] >= 128:
                continue
            for cx, cy, r, colour in reversed(CIRCLES):
                if (x - cx) ** 2 + (y - cy) ** 2 <= (r - 2.5) ** 2:
                    if mode == "night":
                        px[x, y] = NIGHT
                    else:
                        px[x, y] = tuple(int(v * 0.72) for v in colour) + (255,)
                    break
    return logo.crop(logo.getbbox())


def shrink(logo: Image.Image, size: int) -> Image.Image:
    small = logo.resize((size, size), Image.LANCZOS)
    px = small.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255 if a > 110 else 0)
    return small


def outlined(icon: Image.Image, colour) -> Image.Image:
    out = Image.new("RGBA", (icon.width + 2, icon.height + 2), (0, 0, 0, 0))
    src = icon.load()
    dst = out.load()
    for y in range(icon.height):
        for x in range(icon.width):
            if src[x, y][3]:
                for dx in (0, 1, 2):
                    for dy in (0, 1, 2):
                        dst[x + dx, y + dy] = colour
    out.alpha_composite(icon, (1, 1))
    return out


def centred(icon: Image.Image, size) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(icon, ((size[0] - icon.width) // 2, (size[1] - icon.height) // 2))
    return canvas


def main() -> None:
    small = filled("shade")
    centred(outlined(shrink(small, 21), BLACK), (23, 27)).save(
        IMG / "upgradeUI" / "Equipment" / "aug_lock.png", optimize=True)
    centred(outlined(shrink(small, 24), BLACK), (26, 26)).save(
        IMG / "systemUI" / "weapbox_icon_W_ap.png", optimize=True)
    centred(filled("night"), (256, 256)).save(IMG / "ap_logo.png", optimize=True)
    print("logo art written under", IMG)


if __name__ == "__main__":
    main()
