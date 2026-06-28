#!/usr/bin/env python3
"""Create a simple default virtual face image for testing."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / "assets" / "sample-face.png"
W, H = 1080, 1350  # portrait-friendly source


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGB", (W, H), (24, 28, 48))
    draw = ImageDraw.Draw(img)

    # Soft vignette background
    for i in range(40):
        shade = 24 + i
        draw.ellipse((-200 + i * 4, 80 + i * 2, W + 200 - i * 4, H + 200 - i * 2), fill=(shade, shade + 8, shade + 24))

    cx, cy = W // 2, H // 2 - 40

    # Neck / shoulders
    draw.ellipse((cx - 320, cy + 180, cx + 320, cy + 700), fill=(235, 198, 170))
    draw.rectangle((cx - 420, cy + 420, cx + 420, H), fill=(42, 58, 92))

    # Face
    draw.ellipse((cx - 250, cy - 280, cx + 250, cy + 280), fill=(245, 210, 182))

    # Hair
    draw.ellipse((cx - 280, cy - 360, cx + 280, cy + 40), fill=(32, 24, 20))
    draw.rectangle((cx - 280, cy - 120, cx + 280, cy + 20), fill=(32, 24, 20))

    # Eyes
    for ex in (cx - 95, cx + 95):
        draw.ellipse((ex - 42, cy - 70, ex + 42, cy + 18), fill=(255, 255, 255))
        draw.ellipse((ex - 22, cy - 40, ex + 22, cy + 2), fill=(58, 96, 168))
        draw.ellipse((ex - 10, cy - 34, ex + 10, cy - 14), fill=(12, 12, 18))

    # Eyebrows
    draw.arc((cx - 150, cy - 130, cx - 40, cy - 70), start=200, end=340, fill=(40, 30, 24), width=8)
    draw.arc((cx + 40, cy - 130, cx + 150, cy - 70), start=200, end=340, fill=(40, 30, 24), width=8)

    # Nose
    draw.line((cx, cy + 10, cx - 18, cy + 90), fill=(210, 170, 145), width=6)
    draw.line((cx - 18, cy + 90, cx + 18, cy + 90), fill=(210, 170, 145), width=6)

    # Closed mouth baseline (animation opens from here)
    draw.arc((cx - 70, cy + 120, cx + 70, cy + 190), start=10, end=170, fill=(170, 95, 95), width=8)

    # Subtle studio light
    overlay = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.ellipse((cx - 180, cy - 220, cx + 60, cy + 40), fill=(255, 255, 255, 28))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

    img.save(OUT, quality=95)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
