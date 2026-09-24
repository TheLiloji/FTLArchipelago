#!/usr/bin/env python3

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "ArchipelagoFTL/img/stars"
STARS = Path.home() / ".local/share/ftl-extract/vanilla/img/stars"

SKY_W, SKY_H = 1280, 720
PLANET_SIZE = 460
SEED = 20260915

WORLDS = [
    (-90, (0xC9, 0x76, 0x82), "planet_peach", 0.62, (6, -10)),
    (-30, (0x75, 0xC2, 0x75), "planet_brown", 1.05, (14, 6)),
    (30, (0xCA, 0x94, 0xC2), "planet_gas_blue", 0.72, (-8, 14)),
    (90, (0xD9, 0xA0, 0x7D), "planet_gas_yellow", 1.25, (-16, 4)),
    (150, (0x76, 0x7E, 0xBD), "planet_bigblue", 0.90, (10, -6)),
    (-150, (0xEE, 0xE3, 0x91), "planet_red", 0.55, (-12, 8)),
]

WORLDS_2 = [
    (-90, (0xC9, 0x76, 0x82), "planet_red", 0.80, (-10, -6)),
    (-30, (0x75, 0xC2, 0x75), "planet_bigblue", 0.66, (8, 12)),
    (30, (0xCA, 0x94, 0xC2), "planet_brown", 1.02, (-14, -4)),
    (90, (0xD9, 0xA0, 0x7D), "planet_peach", 0.72, (12, 8)),
    (150, (0x76, 0x7E, 0xBD), "planet_gas_yellow", 0.88, (-6, 10)),
    (-150, (0xEE, 0xE3, 0x91), "planet_gas_blue", 0.60, (14, -8)),
]

ORBIT_RX = 150
ORBIT_RY = 64
BASE_RADIUS = 44
RELIEF = 0.30
NIGHT = 0.16
HALO = 0.30

SPARKLES = [(0.50, 0.22, 7), (0.30, 0.66, 5), (0.74, 0.38, 6),
            (0.20, 0.36, 4), (0.64, 0.74, 5), (0.86, 0.60, 4)]
SPARKLES_2 = [(0.38, 0.18, 6), (0.68, 0.28, 4), (0.24, 0.52, 5),
              (0.80, 0.66, 6), (0.52, 0.80, 4), (0.12, 0.72, 5)]


def tint(planet: Image.Image, color, brightness: float) -> Image.Image:

    px = planet.load()
    out_img = Image.new("RGBA", planet.size)
    sp = out_img.load()
    for y in range(planet.size[1]):
        for x in range(planet.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            day = min(1.0, (lum ** 0.8) * 1.9)
            f = (NIGHT + (1.0 - NIGHT) * day) * brightness
            sp[x, y] = (round(color[0] * f), round(color[1] * f), round(color[2] * f), a)
    return out_img


def halo(radius: int, color, strength: float) -> Image.Image:
    t = max(8, int(radius * 4))
    glow = Image.new("RGBA", (t, t), (0, 0, 0, 0))
    r = radius * 1.1
    ImageDraw.Draw(glow).ellipse([t / 2 - r, t / 2 - r, t / 2 + r, t / 2 + r],
                                  fill=(color[0], color[1], color[2], round(255 * strength)))
    return glow.filter(ImageFilter.GaussianBlur(radius * 0.5))


def make_sky() -> None:
    rng = random.Random(SEED)
    background = Image.new("RGB", (SKY_W, SKY_H))
    px = background.load()
    for y in range(SKY_H):
        for x in range(0, SKY_W, 4):
            t = (x / SKY_W) * 0.55 + (y / SKY_H) * 0.45
            color = (int(34 + (12 - 34) * t), int(17 + (9 - 17) * t), int(58 + (22 - 58) * t))
            for dx in range(4):
                if x + dx < SKY_W:
                    px[x + dx, y] = color

    nebula = Image.new("RGB", (SKY_W, SKY_H), (0, 0, 0))
    nd = ImageDraw.Draw(nebula)
    for _ in range(14):
        cx, cy, rad = rng.randint(0, SKY_W), rng.randint(0, SKY_H), rng.randint(120, 320)
        nd.ellipse([cx - rad, cy - rad, cx + rad, cy + rad],
                   fill=rng.choice([(52, 22, 84), (34, 16, 62), (68, 30, 92), (28, 20, 72)]))
    background = ImageChops.add(background, nebula.filter(ImageFilter.GaussianBlur(110)))

    d = ImageDraw.Draw(background)
    for _ in range(700):
        v = rng.randint(90, 190)
        d.point((rng.randint(0, SKY_W - 1), rng.randint(0, SKY_H - 1)),
                fill=(v, v, min(255, v + 25)))
    for _ in range(70):
        x, y = rng.randint(0, SKY_W - 1), rng.randint(0, SKY_H - 1)
        v = rng.randint(200, 255)
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(v, v, 255))

    background.save(IMG / "bg_ap_archipelago.png", optimize=True)
    print(f"sky     : {IMG / 'bg_ap_archipelago.png'}")


def make_planet(worlds, file: str, tilt: int, sparkles) -> None:
    SIZE = PLANET_SIZE
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    center = (SIZE / 2, SIZE / 2 + 10)

    sparkle_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ed = ImageDraw.Draw(sparkle_layer)
    for fx, fy, radius in sparkles:
        x, y = fx * SIZE, fy * SIZE
        for dx, dy in ((radius, 0), (0, radius)):
            ed.line([(x - dx, y - dy), (x + dx, y + dy)], fill=(225, 215, 255, 170), width=2)
        ed.ellipse([x - 1.5, y - 1.5, x + 1.5, y + 1.5], fill=(255, 250, 255, 225))
    canvas.alpha_composite(sparkle_layer.filter(ImageFilter.GaussianBlur(0.6)))

    for angle, color, texture, scale, offset in sorted(
            worlds, key=lambda m: math.sin(math.radians(m[0]))):
        depth = math.sin(math.radians(angle))
        radius = round(BASE_RADIUS * scale * (1 + RELIEF * depth))
        brightness = 0.72 + 0.28 * (depth + 1) / 2

        source = Image.open(STARS / f"{texture}.png").convert("RGBA")
        world_img = tint(source, color, brightness).resize((radius * 2, radius * 2), Image.LANCZOS)
        cx = center[0] + ORBIT_RX * math.cos(math.radians(angle)) + offset[0]
        cy = center[1] + tilt * depth + offset[1]

        glow = halo(radius, color, HALO * brightness)
        layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        layer.paste(glow, (round(cx - glow.width / 2), round(cy - glow.height / 2)))
        canvas.alpha_composite(layer)
        canvas.alpha_composite(world_img, (round(cx - radius), round(cy - radius)))

    bbox = canvas.getbbox()
    if bbox is not None and (bbox[0] == 0 or bbox[1] == 0 or bbox[2] == SIZE or bbox[3] == SIZE):
        raise SystemExit(
            f"{file}: the drawing touches the edge of the canvas ({bbox} for {SIZE}x{SIZE}).\n"
            "Reduce `scale` on the worlds involved, or `ORBIT_RX`."
        )

    canvas.save(IMG / file, optimize=True)
    print(f"planet  : {IMG / file}  (content {bbox})")


def main() -> None:
    if not STARS.is_dir():
        raise SystemExit(
            f"FTL resources not found: {STARS}\n"
            "Extract them first: "
            "ftlman extract ~/.local/share/ftl-extract/vanilla <data>/ftl.dat.vanilla"
        )
    IMG.mkdir(parents=True, exist_ok=True)
    make_sky()
    make_planet(WORLDS, "planet_ap_archipelago.png", ORBIT_RY, SPARKLES)
    make_planet(WORLDS_2, "planet_ap_archipelago_2.png", 54, SPARKLES_2)


if __name__ == "__main__":
    main()
