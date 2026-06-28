# AvatarFace Automation

Make YouTube Shorts automatically on your Ubuntu laptop.

## One-time setup

```bash
cd ~/avatar-face
chmod +x run.sh setup-automation.sh automate.sh
./run.sh --setup
nano config.env
```

## Daily commands

| Command | What it does |
|---------|----------------|
| `./run.sh` | Generate all videos from `inbox/` |
| `./run.sh "Your script text"` | Make one short instantly |
| `./run.sh --watch` | Auto-generate when you drop `.txt` files in `inbox/` |
| `./automate.sh daily` | Create face + batch + show latest video |

## Workflow

### 1. Write scripts

Put `.txt` files in `inbox/`:

```text
---
title: My Short Title
voice: en-IN-NeerjaNeural
rate: +0%
---
Namaste! This is what the avatar says in the video.
```

Copy examples:

```bash
cp scripts/examples/*.txt inbox/
nano inbox/my-new-short.txt
```

### 2. Generate videos

```bash
./run.sh
```

Videos appear in `output/`. Used scripts move to `inbox/done/`.

### 3. Upload to YouTube

Open videos and upload as Shorts:

```bash
xdg-open output/*.mp4
```

## Scheduled automation (runs every day)

### Option A — Cron (simple)

```bash
./setup-automation.sh --cron
```

Runs `./run.sh --batch` every day at **9:00 AM**.  
Log: `output/automation.log`

### Option B — Systemd timer (recommended)

```bash
./setup-automation.sh --systemd
```

Check status:

```bash
systemctl --user status avatar-face.timer
systemctl --user start avatar-face.service   # run now
```

### Remove schedule

```bash
./setup-automation.sh --remove
```

## Config (`config.env`)

```bash
AVATAR_IMAGE="assets/indian-host-face.png"
AVATAR_VOICE="en-IN-NeerjaNeural"
AVATAR_RATE="+0%"
AVATAR_ENGINE="fast"
AVATAR_OPEN_VIDEO="false"
```

## Indian voices

| Voice | Use for |
|-------|---------|
| `en-IN-NeerjaNeural` | Female Indian English |
| `en-IN-PrabhatNeural` | Male Indian English |
| `hi-IN-SwaraNeural` | Female Hindi |
| `hi-IN-MadhurNeural` | Male Hindi |

List all: `./automate.sh voices`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Virtual env missing` | `./run.sh --setup` |
| `No scripts in inbox/` | `cp scripts/examples/*.txt inbox/` |
| Cron not running | `crontab -l` and check log at `output/automation.log` |
| Wrong voice | Edit `config.env` or frontmatter in script file |
