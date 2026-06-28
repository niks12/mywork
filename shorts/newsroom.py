"""Newsroom compositing for Priya YouTube news videos."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
DEFAULT_BG = ROOT / "assets" / "newsroom-background.png"
ANCHOR_BOX = (190, 520, 890, 1540)  # x1, y1, x2, y2 on 1080x1920


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def load_newsroom_background(path: Path | None = None) -> Image.Image:
    bg_path = path or DEFAULT_BG
    if not bg_path.exists():
        raise FileNotFoundError(f"Newsroom background missing: {bg_path}")
    return Image.open(bg_path).convert("RGB")


def fit_anchor(face: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    src = face.convert("RGB")
    ratio = min(tw / src.width, th / src.height)
    nw, nh = int(src.width * ratio), int(src.height * ratio)
    resized = src.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (tw, th), (24, 32, 58))
    ox, oy = (tw - nw) // 2, th - nh
    canvas.paste(resized, (ox, oy))
    return canvas


def mouth_on_anchor(anchor: Image.Image, amplitude: float, blink: bool) -> Image.Image:
    frame = anchor.copy()
    draw = ImageDraw.Draw(frame)
    w, h = frame.size
    cx, cy = w // 2, int(h * 0.52)
    mouth_w = int(w * 0.09)
    mouth_h = int(h * 0.04)
    if blink:
        for ex in (cx - int(w * 0.11), cx + int(w * 0.11)):
            draw.rectangle((ex - 28, cy - 95, ex + 28, cy - 55), fill=(22, 16, 14))
    open_h = int(mouth_h * (0.3 + amplitude * 2.2))
    draw.ellipse((cx - mouth_w, cy - open_h // 3, cx + mouth_w, cy + open_h), fill=(42, 16, 20))
    draw.arc((cx - mouth_w, cy - open_h // 2, cx + mouth_w, cy + open_h), 185, 355, fill=(155, 68, 75), width=4)
    return frame


def composite_news_frame(
    background: Image.Image,
    anchor: Image.Image,
    amplitude: float,
    blink: bool,
    headline: str,
    ticker: str,
) -> Image.Image:
    frame = background.copy()
    animated = mouth_on_anchor(anchor, amplitude, blink)
    x1, y1, x2, y2 = ANCHOR_BOX
    frame.paste(animated, (x1, y1))

    draw = ImageDraw.Draw(frame)
    w, h = frame.size

    # Headline lower-third
    if headline.strip():
        text = headline.strip().upper()[:60]
        font = _font(34, True)
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        tx = max(24, (w - tw) // 2)
        ty = h - 148
        draw.rectangle((0, h - 160, w, h - 100), fill=(180, 24, 32))
        draw.text((tx, ty), text, fill=(255, 255, 255), font=font)

    # Scrolling-style ticker line
    if ticker.strip():
        draw.rectangle((0, h - 100, w, h), fill=(10, 16, 36))
        draw.text((24, h - 82), f"BREAKING  |  {ticker.strip()[:80]}", fill=(255, 220, 80), font=_font(26, True))

    return frame
