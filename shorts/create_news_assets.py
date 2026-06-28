#!/usr/bin/env python3
"""Generate Priya news-anchor portrait and newsroom background for YouTube."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
MYWORK = ROOT.parent
ANCHOR_OUT = MYWORK / "avatars" / "priya" / "assets" / "avatar-news.png"
ANCHOR_WEB = MYWORK / "public" / "avatars" / "priya" / "assets" / "avatar-news.png"
BG_OUT = ROOT / "assets" / "newsroom-background.png"
W, H = 1080, 1920


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def create_newsroom_background() -> Image.Image:
    img = Image.new("RGB", (W, H), (12, 22, 48))
    draw = ImageDraw.Draw(img)

    # Studio wall gradient
    for y in range(H):
        t = y / H
        draw.line((0, y, W, y), fill=(int(18 + 30 * t), int(28 + 20 * t), int(58 + 40 * t)))

    # Back screens (left / right)
    for sx, label in ((60, "MARKETS"), (W - 360, "WORLD")):
        draw.rounded_rectangle((sx, 180, sx + 300, 520), radius=12, fill=(8, 14, 32), outline=(50, 90, 160), width=3)
        for i in range(6):
            bh = 28 + i * 18
            draw.rectangle((sx + 20, 240 + i * 38, sx + 80 + i * 25, 240 + i * 38 + bh), fill=(30 + i * 12, 80 + i * 8, 140))
        draw.text((sx + 20, 195), label, fill=(180, 200, 255), font=_font(22, True))

    # Top news banner
    draw.rectangle((0, 0, W, 120), fill=(180, 24, 32))
    draw.rectangle((0, 118, W, 128), fill=(255, 210, 60))
    draw.text((36, 28), "PRIYA NEWS", fill=(255, 255, 255), font=_font(52, True))
    draw.text((W - 200, 42), "LIVE", fill=(255, 80, 80), font=_font(36, True))
    draw.ellipse((W - 240, 52, W - 220, 72), fill=(255, 40, 40))

    # Desk
    draw.polygon([(0, 1480), (W, 1480), (W, H), (0, H)], fill=(20, 16, 14))
    draw.polygon([(80, 1480), (W - 80, 1480), (W - 140, 1560), (140, 1560)], fill=(38, 32, 28))
    draw.rectangle((0, 1558, W, 1580), fill=(90, 75, 60))

    # Lower third strip
    draw.rectangle((0, H - 160, W, H - 100), fill=(180, 24, 32))
    draw.rectangle((0, H - 100, W, H), fill=(10, 16, 36))

    # Subtle spotlight on anchor area
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.ellipse((W // 2 - 380, 700, W // 2 + 380, 1500), fill=(255, 255, 255, 18))
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


def create_news_anchor() -> Image.Image:
    """Priya as professional news reader — original fictional character."""
    img = Image.new("RGB", (900, 1100), (24, 32, 58))
    draw = ImageDraw.Draw(img)
    cx = 450

    # Blazer / shoulders
    draw.polygon([(0, 700), (900, 700), (900, 1100), (0, 1100)], fill=(24, 42, 88))
    draw.polygon([(120, 680), (780, 680), (900, 1100), (0, 1100)], fill=(28, 48, 96))
    draw.polygon([(300, 680), (600, 680), (520, 820), (380, 820)], fill=(240, 235, 230))  # blouse

    # Neck
    draw.rectangle((380, 560, 520, 700), fill=(232, 188, 152))

    # Face
    draw.ellipse((250, 120, 650, 600), fill=(238, 196, 158))

    # Hair — neat anchor style
    draw.ellipse((220, 40, 680, 380), fill=(22, 16, 14))
    draw.rectangle((220, 180, 680, 320), fill=(22, 16, 14))

    # Small bindi
    draw.ellipse((438, 248, 462, 272), fill=(196, 32, 48))

    # Eyes
    for ex in (360, 540):
        draw.ellipse((ex - 44, 300, ex + 44, 372), fill=(255, 252, 248))
        draw.ellipse((ex - 24, 322, ex + 24, 358), fill=(48, 32, 22))
        draw.ellipse((ex - 10, 330, ex + 10, 348), fill=(10, 10, 14))

    # Brows — professional
    draw.arc((300, 268, 430, 318), 200, 340, fill=(32, 22, 18), width=6)
    draw.arc((470, 268, 600, 318), 200, 340, fill=(32, 22, 18), width=6)

    # Nose + lips baseline
    draw.line((450, 380, 430, 450), fill=(200, 155, 120), width=5)
    draw.arc((410, 470, 490, 520), 15, 165, fill=(168, 72, 82), width=8)

    # Blazer lapels
    draw.line((300, 700, 450, 820), fill=(18, 32, 72), width=8)
    draw.line((600, 700, 450, 820), fill=(18, 32, 72), width=8)

    # Lapel mic dot
    draw.ellipse((470, 790, 490, 810), fill=(40, 40, 44))
    draw.ellipse((474, 794, 486, 806), fill=(80, 80, 88))

    # Studio light
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.ellipse((280, 140, 500, 400), fill=(255, 255, 255, 24))
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


def main() -> None:
    ANCHOR_OUT.parent.mkdir(parents=True, exist_ok=True)
    ANCHOR_WEB.parent.mkdir(parents=True, exist_ok=True)
    BG_OUT.parent.mkdir(parents=True, exist_ok=True)

    anchor = create_news_anchor()
    anchor.save(ANCHOR_OUT, quality=95)
    anchor.save(ANCHOR_WEB, quality=95)
    # Default avatar for web UI
    anchor.save(ANCHOR_OUT.parent / "avatar.png", quality=95)
    anchor.save(ANCHOR_WEB.parent / "avatar.png", quality=95)

    bg = create_newsroom_background()
    bg.save(BG_OUT, quality=95)

    print(f"News anchor: {ANCHOR_OUT}")
    print(f"Newsroom BG: {BG_OUT}")


if __name__ == "__main__":
    main()
