#!/usr/bin/env python3
"""Process all scripts in scripts/queue/ that are not yet marked done."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "scripts" / "queue"
STATE = ROOT / ".state" / "processed.json"
GENERATE = ROOT / "generate_short.py"


def load_state() -> dict:
    if not STATE.exists():
        return {"processed": []}
    return json.loads(STATE.read_text(encoding="utf-8"))


def save_state(state: dict) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def file_id(path: Path) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()[:16]
    return f"{path.name}:{digest}"


def parse_script(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    title = path.stem.replace("-", " ").title()
    voice = ""
    rate = "+0%"
    body = text

    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) >= 3:
            front = parts[1]
            body = parts[2].strip()
            for line in front.splitlines():
                if ":" in line:
                    key, value = line.split(":", 1)
                    key = key.strip().lower()
                    value = value.strip()
                    if key == "title":
                        title = value
                    elif key == "voice":
                        voice = value
                    elif key == "rate":
                        rate = value
    return {"title": title, "voice": voice, "rate": rate, "text": body}


def load_config() -> dict:
    cfg = {}
    for name in ("config.env", "config.env.example"):
        path = ROOT / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            cfg[key.strip()] = value.strip().strip('"')
    return cfg


def main() -> int:
    cfg = load_config()
    image = ROOT / cfg.get("AVATAR_IMAGE", "assets/indian-host-face.png")
    default_voice = cfg.get("AVATAR_VOICE", "en-IN-NeerjaNeural")
    default_rate = cfg.get("AVATAR_RATE", "+0%")
    engine = cfg.get("AVATAR_ENGINE", "fast")
    style = cfg.get("AVATAR_STYLE", "newsroom")
    background = ROOT / cfg.get("AVATAR_BACKGROUND", "assets/newsroom-background.png")
    output_dir = ROOT / cfg.get("AVATAR_OUTPUT", "output")
    output_dir.mkdir(parents=True, exist_ok=True)

    state = load_state()
    processed = set(state.get("processed", []))
    made = 0

    for script in sorted(QUEUE.glob("*.txt")):
        sid = file_id(script)
        if sid in processed:
            continue
        meta = parse_script(script)
        voice = meta["voice"] or default_voice
        out = output_dir / f"{script.stem}.mp4"

        cmd = [
            sys.executable,
            str(GENERATE),
            "--text",
            meta["text"],
            "--title",
            meta["title"],
            "--output",
            str(out),
            "--image",
            str(image if image.is_absolute() else ROOT / image),
            "--voice",
            voice,
            "--rate",
            meta["rate"] or default_rate,
            "--engine",
            engine,
            "--style",
            style,
        ]
        if style == "newsroom":
            cmd.extend(["--background", str(background if background.is_absolute() else ROOT / background)])
            cmd.extend(["--ticker", meta["title"]])
        print(f"==> Auto-processing: {script.name}")
        subprocess.run(cmd, check=True, cwd=ROOT)
        processed.add(sid)
        made += 1

    state["processed"] = sorted(processed)
    save_state(state)
    print(f"==> Queue complete. New videos: {made}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
