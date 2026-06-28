#!/usr/bin/env python3
"""Create an original stylized Indian virtual host face (fictional character, not a celebrity)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / "assets" / "indian-host-face.png"
W, H = 1080, 1350


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)

    # Warm studio gradient background
    img = Image.new("RGB", (W, H), (28, 18, 32))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        color = (
            int(42 + 30 * t),
            int(22 + 18 * t),
            int(58 + 35 * t),
        )
        draw.line((0, y, W, y), fill=color)

    cx, cy = W // 2, H // 2 - 30

    # Traditional-inspired blouse / shoulders
    draw.polygon(
        [(cx - 380, H), (cx - 220, cy + 360), (cx + 220, cy + 360), (cx + 380, H)],
        fill=(168, 32, 72),
    )
    draw.polygon(
        [(cx - 200, cy + 360), (cx, cy + 250), (cx + 200, cy + 360)],
        fill=(212, 175, 98),
    )
    draw.ellipse((cx - 300, cy + 200, cx + 300, cy + 620), fill=(224, 178, 138))

    # Face — original stylized South Asian features
    draw.ellipse((cx - 245, cy - 270, cx + 245, cy + 290), fill=(238, 196, 158))

    # Long dark hair with side flow
    draw.ellipse((cx - 290, cy - 380, cx + 290, cy + 60), fill=(18, 12, 10))
    draw.rectangle((cx - 290, cy - 140, cx + 290, cy + 40), fill=(18, 12, 10))
    draw.ellipse((cx - 330, cy - 60, cx - 120, cy + 220), fill=(18, 12, 10))
    draw.ellipse((cx + 120, cy - 60, cx + 330, cy + 220), fill=(18, 12, 10))

    # Bindi
    draw.ellipse((cx - 10, cy - 155, cx + 10, cy - 135), fill=(196, 32, 64))

    # Almond eyes
    for ex in (cx - 92, cx + 92):
        draw.ellipse((ex - 48, cy - 62, ex + 48, cy + 22), fill=(255, 252, 245))
        draw.ellipse((ex - 28, cy - 38, ex + 28, cy + 4), fill=(62, 38, 24))
        draw.ellipse((ex - 12, cy - 30, ex + 12, cy - 10), fill=(8, 8, 12))
        # Eyeliner accent
        draw.arc((ex - 50, cy - 58, ex + 50, cy + 18), start=200, end=340, fill=(24, 14, 10), width=4)

    # Soft arched brows
    draw.arc((cx - 155, cy - 118, cx - 35, cy - 72), start=205, end=335, fill=(36, 22, 16), width=7)
    draw.arc((cx + 35, cy - 118, cx + 155, cy - 72), start=205, end=335, fill=(36, 22, 16), width=7)

    # Nose
    draw.line((cx, cy + 18, cx - 14, cy + 88), fill=(198, 150, 118), width=5)
    draw.arc((cx - 22, cy + 72, cx + 22, cy + 102), start=15, end=165, fill=(188, 140, 110), width=4)

    # Lips (animation baseline)
    draw.arc((cx - 62, cy + 118, cx + 62, cy + 178), start=10, end=170, fill=(168, 62, 78), width=9)

    # Subtle cheek highlight
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    for hx in (cx - 120, cx + 120):
        odraw.ellipse((hx - 40, cy + 20, hx + 40, cy + 100), fill=(255, 210, 180, 35))
    odraw.ellipse((cx - 160, cy - 210, cx + 40, cy + 20), fill=(255, 255, 255, 22))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

    img.save(OUT, quality=95)
    print(f"Wrote {OUT}")
    print("Original fictional host — not based on any real person.")


if __name__ == "__main__":
    main()
