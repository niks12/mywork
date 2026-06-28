#!/usr/bin/env python3
"""
Generate a vertical talking-face short from text.

Fast mode (default): edge-tts speech + audio-reactive mouth animation (CPU).
Quality mode: delegates to SadTalker when installed (--engine sadtalker).
"""

from __future__ import annotations

import argparse
import asyncio
import json
import math
import shutil
import subprocess
import sys
import tempfile
import wave
from dataclasses import dataclass
from pathlib import Path

import edge_tts
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent
DEFAULT_FACE = ROOT / "assets" / "sample-face.png"
DEFAULT_NEWS_FACE = ROOT.parent / "avatars" / "priya" / "assets" / "avatar-news.png"
DEFAULT_VOICE = "en-IN-NeerjaNeural"
SHORTS_SIZE = (1080, 1920)
FPS = 30


@dataclass(frozen=True)
class AudioEnvelope:
    samples: np.ndarray
    sample_rate: int

    @property
    def duration(self) -> float:
        return len(self.samples) / self.sample_rate

    def amplitude_at(self, t: float) -> float:
        if self.duration <= 0:
            return 0.0
        idx = int(min(max(t, 0.0), self.duration - 1e-6) * self.sample_rate)
        return float(self.samples[idx])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a speaking virtual face video for YouTube Shorts / Reels."
    )
    parser.add_argument(
        "--text",
        required=True,
        help="Script the avatar should speak.",
    )
    parser.add_argument(
        "--image",
        type=Path,
        default=DEFAULT_FACE,
        help=f"Portrait image path (default: {DEFAULT_FACE})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("output/short.mp4"),
        help="Output MP4 path (default: output/short.mp4)",
    )
    parser.add_argument(
        "--voice",
        default=DEFAULT_VOICE,
        help=f"edge-tts voice name (default: {DEFAULT_VOICE})",
    )
    parser.add_argument(
        "--rate",
        default="+0%",
        help="Speech rate, e.g. +10%% or -5%% (edge-tts format).",
    )
    parser.add_argument(
        "--title",
        default="",
        help="Optional title overlay at the top of the video.",
    )
    parser.add_argument(
        "--engine",
        choices=("fast", "sadtalker"),
        default="fast",
        help="fast = CPU animation; sadtalker = photoreal lip-sync (needs GPU/CPU setup).",
    )
    parser.add_argument(
        "--style",
        choices=("newsroom", "portrait"),
        default="newsroom",
        help="newsroom = Priya news anchor with studio background (default); portrait = plain face fill",
    )
    parser.add_argument(
        "--background",
        type=Path,
        default=ROOT / "assets" / "newsroom-background.png",
        help="Newsroom background image (newsroom style only).",
    )
    parser.add_argument(
        "--ticker",
        default="",
        help="Optional ticker text for newsroom lower bar.",
    )
    parser.add_argument(
        "--list-voices",
        action="store_true",
        help="Print available edge-tts voices and exit.",
    )
    return parser.parse_args()


async def list_voices() -> None:
    voices = await edge_tts.list_voices()
    for voice in sorted(voices, key=lambda v: (v["Locale"], v["ShortName"])):
        print(f"{voice['ShortName']:28} {voice['Gender']:6} {voice['Locale']}")


async def synthesize_speech(text: str, voice: str, rate: str, wav_path: Path) -> None:
    communicate = edge_tts.Communicate(text=text, voice=voice, rate=rate)
    mp3_path = wav_path.with_suffix(".mp3")
    await communicate.save(str(mp3_path))
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(mp3_path),
            "-ar",
            "22050",
            "-ac",
            "1",
            str(wav_path),
        ],
        check=True,
        capture_output=True,
    )
    mp3_path.unlink(missing_ok=True)


def load_envelope(wav_path: Path, frame_rate: int = FPS) -> AudioEnvelope:
    with wave.open(str(wav_path), "rb") as wf:
        sample_rate = wf.getframerate()
        frames = wf.readframes(wf.getnframes())

    audio = np.frombuffer(frames, dtype=np.int16).astype(np.float32)
    if audio.size == 0:
        return AudioEnvelope(samples=np.zeros(1, dtype=np.float32), sample_rate=frame_rate)

    # Downsample to per-video-frame RMS envelope for smooth mouth motion.
    samples_per_frame = max(1, int(sample_rate / frame_rate))
    chunks = [
        audio[i : i + samples_per_frame]
        for i in range(0, len(audio), samples_per_frame)
    ]
    rms = np.array(
        [float(np.sqrt(np.mean(np.square(chunk)))) if chunk.size else 0.0 for chunk in chunks],
        dtype=np.float32,
    )
    peak = float(np.percentile(rms, 95)) or 1.0
    normalized = np.clip(rms / peak, 0.0, 1.0)
    return AudioEnvelope(samples=normalized, sample_rate=frame_rate)


def fit_portrait(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    src = image.convert("RGB")
    src_ratio = src.width / src.height
    target_ratio = target_w / target_h

    if src_ratio > target_ratio:
        # Wider than target: crop sides.
        new_h = src.height
        new_w = int(new_h * target_ratio)
        left = (src.width - new_w) // 2
        cropped = src.crop((left, 0, left + new_w, new_h))
    else:
        # Taller than target: crop top/bottom, bias toward face (upper crop).
        new_w = src.width
        new_h = int(new_w / target_ratio)
        top = max(0, int((src.height - new_h) * 0.18))
        cropped = src.crop((0, top, new_w, min(src.height, top + new_h)))

    return cropped.resize(size, Image.Resampling.LANCZOS)


def mouth_geometry(width: int, height: int) -> tuple[int, int, int, int]:
    cx = width // 2
    cy = int(height * 0.62)
    mouth_w = int(width * 0.16)
    mouth_h = int(height * 0.05)
    return cx, cy, mouth_w, mouth_h


def draw_talking_frame(
    base: Image.Image,
    amplitude: float,
    frame_idx: int,
    blink: bool,
) -> Image.Image:
    frame = base.copy()
    draw = ImageDraw.Draw(frame)
    w, h = frame.size
    cx, cy, mouth_w, mouth_h = mouth_geometry(w, h)

    # Gentle breathing / emphasis zoom.
    pulse = 1.0 + amplitude * 0.018
    if pulse > 1.001:
        zoomed = frame.resize(
            (int(w * pulse), int(h * pulse)),
            Image.Resampling.LANCZOS,
        )
        left = (zoomed.width - w) // 2
        top = int((zoomed.height - h) * 0.42)
        frame = zoomed.crop((left, top, left + w, top + h))
        draw = ImageDraw.Draw(frame)
        cx, cy, mouth_w, mouth_h = mouth_geometry(w, h)

    # Blink
    if blink:
        for ex in (cx - int(w * 0.09), cx + int(w * 0.09)):
            draw.rectangle(
                (ex - int(w * 0.04), cy - int(h * 0.12), ex + int(w * 0.04), cy - int(h * 0.05)),
                fill=(36, 28, 24),
            )

    # Mouth opening driven by speech amplitude.
    open_h = int(mouth_h * (0.25 + amplitude * 2.4))
    lip_color = (150, 72, 78)
    inner_color = (48, 18, 22)
    draw.ellipse(
        (cx - mouth_w, cy - open_h // 3, cx + mouth_w, cy + open_h),
        fill=inner_color,
    )
    draw.arc(
        (cx - mouth_w, cy - open_h // 2, cx + mouth_w, cy + open_h),
        start=185,
        end=355,
        fill=lip_color,
        width=max(3, w // 180),
    )

    # Soft vignette for shorts aesthetic.
    overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.rectangle((0, 0, w, h), fill=(0, 0, 0, 35))
    odraw.rectangle((0, int(h * 0.82), w, h), fill=(0, 0, 0, 70))
    frame = Image.alpha_composite(frame.convert("RGBA"), overlay).convert("RGB")
    return frame


def wrap_title(text: str, max_chars: int = 28) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        candidate = " ".join(current + [word])
        if len(candidate) <= max_chars:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines[:3]


def draw_title(frame: Image.Image, title: str) -> Image.Image:
    if not title.strip():
        return frame
    out = frame.copy()
    draw = ImageDraw.Draw(out)
    w, _ = out.size
    y = int(out.height * 0.08)
    for line in wrap_title(title):
        bbox = draw.textbbox((0, 0), line)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        x = (w - tw) // 2
        pad = 18
        draw.rounded_rectangle(
            (x - pad, y - pad, x + tw + pad, y + th + pad),
            radius=16,
            fill=(10, 10, 18, 210),
        )
        draw.text((x, y), line, fill=(255, 255, 255))
        y += th + pad
    return out


def render_newsroom_video(
    image_path: Path,
    background_path: Path,
    envelope: AudioEnvelope,
    wav_path: Path,
    output_path: Path,
    title: str,
    ticker: str,
) -> None:
    from newsroom import composite_news_frame, fit_anchor, load_newsroom_background

    background = load_newsroom_background(background_path)
    anchor = fit_anchor(Image.open(image_path), (700, 1020))
    total_frames = max(1, int(math.ceil(envelope.duration * FPS)))
    ticker_text = ticker or title

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="avatar-news-") as tmp:
        frames_dir = Path(tmp) / "frames"
        frames_dir.mkdir()
        blink_period = int(FPS * 4.5)

        for i in range(total_frames):
            t = i / FPS
            amp = envelope.amplitude_at(t)
            blink = (i % blink_period) in (0, 1, 2)
            frame = composite_news_frame(background, anchor, amp, blink, title, ticker_text)
            frame.save(frames_dir / f"frame_{i:05d}.png")

        silent_video = Path(tmp) / "silent.mp4"
        subprocess.run(
            [
                "ffmpeg", "-y", "-framerate", str(FPS),
                "-i", str(frames_dir / "frame_%05d.png"),
                "-c:v", "libx264", "-pix_fmt", "yuv420p", str(silent_video),
            ],
            check=True, capture_output=True,
        )
        subprocess.run(
            [
                "ffmpeg", "-y", "-i", str(silent_video), "-i", str(wav_path),
                "-c:v", "copy", "-c:a", "aac", "-shortest", str(output_path),
            ],
            check=True, capture_output=True,
        )


def render_fast_video(
    image_path: Path,
    envelope: AudioEnvelope,
    wav_path: Path,
    output_path: Path,
    title: str,
) -> None:
    base = fit_portrait(Image.open(image_path), SHORTS_SIZE)
    total_frames = max(1, int(math.ceil(envelope.duration * FPS)))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="avatar-shorts-") as tmp:
        frames_dir = Path(tmp) / "frames"
        frames_dir.mkdir()
        blink_period = int(FPS * 4.2)

        for i in range(total_frames):
            t = i / FPS
            amp = envelope.amplitude_at(t)
            blink = (i % blink_period) in (0, 1, 2)
            frame = draw_talking_frame(base, amp, i, blink=blink)
            frame = draw_title(frame, title)
            frame.save(frames_dir / f"frame_{i:05d}.png")

        silent_video = Path(tmp) / "silent.mp4"
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-framerate",
                str(FPS),
                "-i",
                str(frames_dir / "frame_%05d.png"),
                "-c:v",
                "libx264",
                "-pix_fmt",
                "yuv420p",
                str(silent_video),
            ],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i",
                str(silent_video),
                "-i",
                str(wav_path),
                "-c:v",
                "copy",
                "-c:a",
                "aac",
                "-shortest",
                str(output_path),
            ],
            check=True,
            capture_output=True,
        )


def find_sadtalker() -> Path | None:
    candidates = [
        ROOT / "vendor" / "SadTalker",
        Path.home() / "SadTalker",
        Path("/opt/SadTalker"),
    ]
    for path in candidates:
        if (path / "inference.py").exists():
            return path
    return None


def render_sadtalker_video(
    image_path: Path,
    wav_path: Path,
    output_path: Path,
) -> None:
    sadtalker = find_sadtalker()
    if sadtalker is None:
        raise SystemExit(
            "SadTalker not found. Run tools/avatar-shorts/setup_sadtalker.sh first, "
            "or use --engine fast."
        )

    with tempfile.TemporaryDirectory(prefix="sadtalker-out-") as tmp:
        result_dir = Path(tmp)
        cmd = [
            sys.executable,
            str(sadtalker / "inference.py"),
            "--driven_audio",
            str(wav_path),
            "--source_image",
            str(image_path),
            "--result_dir",
            str(result_dir),
            "--still",
            "--preprocess",
            "crop",
            "--cpu",
        ]
        subprocess.run(cmd, check=True, cwd=sadtalker)

        generated = sorted(result_dir.rglob("*.mp4"))
        if not generated:
            raise RuntimeError("SadTalker finished but no MP4 was produced.")

        raw = generated[-1]
        output_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i",
                str(raw),
                "-vf",
                f"scale={SHORTS_SIZE[0]}:{SHORTS_SIZE[1]}:force_original_aspect_ratio=increase,"
                f"crop={SHORTS_SIZE[0]}:{SHORTS_SIZE[1]}",
                "-c:v",
                "libx264",
                "-c:a",
                "aac",
                "-pix_fmt",
                "yuv420p",
                str(output_path),
            ],
            check=True,
            capture_output=True,
        )


async def async_main() -> None:
    args = parse_args()
    if args.list_voices:
        await list_voices()
        return

    if not args.image.exists():
        raise SystemExit(
            f"Face image not found: {args.image}\n"
            f"Run: python {ROOT / 'create_sample_face.py'}"
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="avatar-audio-") as tmp:
        wav_path = Path(tmp) / "speech.wav"
        print(f"Generating speech with voice {args.voice}...")
        await synthesize_speech(args.text, args.voice, args.rate, wav_path)
        envelope = load_envelope(wav_path)
        print(f"Audio length: {envelope.duration:.1f}s")

        if args.engine == "sadtalker":
            print("Rendering with SadTalker (this can take several minutes on CPU)...")
            render_sadtalker_video(args.image, wav_path, args.output)
        elif args.style == "newsroom":
            print("Rendering Priya newsroom anchor video...")
            render_newsroom_video(
                args.image, args.background, envelope, wav_path,
                args.output, args.title, args.ticker,
            )
        else:
            print("Rendering fast CPU talking animation...")
            render_fast_video(args.image, envelope, wav_path, args.output, args.title)

    print(f"Done: {args.output.resolve()}")
    meta = {
        "text": args.text,
        "voice": args.voice,
        "engine": args.engine,
        "style": args.style,
        "size": list(SHORTS_SIZE),
        "duration_sec": round(envelope.duration, 2),
        "output": str(args.output.resolve()),
    }
    meta_path = args.output.with_suffix(".json")
    meta_path.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    print(f"Metadata: {meta_path.resolve()}")


def main() -> None:
    asyncio.run(async_main())


if __name__ == "__main__":
    main()
