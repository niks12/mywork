#!/usr/bin/env python3
"""Auto-create a daily short script from scripts/topics.txt — no manual writing."""

from __future__ import annotations

import random
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TOPICS = ROOT / "scripts" / "topics.txt"
DONE = ROOT / ".state" / "topics-done.txt"
QUEUE = ROOT / "scripts" / "queue"
INBOX = ROOT / "inbox"

HOOKS = [
    "Namaste friends! Stop scrolling for ten seconds.",
    "Hey everyone! Quick tip coming your way.",
    "Listen up! This one small change can help you today.",
    "Namaste! Here is something useful for your day.",
]

CLOSERS = [
    "Follow for more Shorts like this every day!",
    "Save this Short and subscribe for daily tips!",
    "Hit subscribe if you want more videos like this!",
    "Follow me for a new Short every single day!",
]

BODIES = [
    "Today let's talk about {topic}. Keep it simple, stay consistent, and results will follow.",
    "Today's topic is {topic}. Try this today and tell me what you think in the comments.",
    "Here is a quick idea about {topic}. Small steps every day create big results.",
    "Let me share a fast tip on {topic}. This works for beginners and experts alike.",
]


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")[:48] or "daily-short"


def load_done() -> set[str]:
    if not DONE.exists():
        return set()
    return {line.strip() for line in DONE.read_text(encoding="utf-8").splitlines() if line.strip()}


def pick_topic(done: set[str]) -> str | None:
    if not TOPICS.exists():
        return None
    topics = [line.strip() for line in TOPICS.read_text(encoding="utf-8").splitlines() if line.strip()]
    # Prefer topics not used yet; reset when all used.
    remaining = [t for t in topics if t not in done]
    pool = remaining or topics
    if not pool:
        return None
    return random.choice(pool)


def build_script(topic: str) -> tuple[str, str]:
    title = topic.title()[:40]
    hook = random.choice(HOOKS)
    body = random.choice(BODIES).format(topic=topic.lower())
    closer = random.choice(CLOSERS)
    text = f"{hook} {body} {closer}"
    return title, text


def main() -> int:
    DONE.parent.mkdir(parents=True, exist_ok=True)
    QUEUE.mkdir(parents=True, exist_ok=True)
    INBOX.mkdir(parents=True, exist_ok=True)

    done = load_done()
    topic = pick_topic(done)
    if not topic:
        print("No topics in scripts/topics.txt — skipping auto script.")
        return 0

    title, text = build_script(topic)
    stamp = date.today().strftime("%Y%m%d")
    slug = slugify(topic)
    filename = f"auto-{stamp}-{slug}.txt"
    out = QUEUE / filename

    if out.exists():
        print(f"Already generated today: {out}")
        return 0

    content = f"""---
title: {title}
voice: en-IN-NeerjaNeural
rate: +0%
---
{text}
"""
    out.write_text(content, encoding="utf-8")
    DONE.write_text("\n".join(sorted(done | {topic})) + "\n", encoding="utf-8")
    print(f"Created auto script: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
