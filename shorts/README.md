# AvatarFace

**Standalone project** — speaking virtual face videos for **YouTube Shorts** and **Instagram Reels** (1080×1920).

This is **not** part of Limagica or any other project.

## First-time setup (empty GitHub repo + empty laptop folder)

If your `~/avatar-face` folder is empty and `git commit` says **nothing to commit**, you need the project files first.

### Option 1 — Bootstrap script (recommended)

1. Copy `bootstrap.sh` onto your laptop (USB, cloud drive, or download from your dev machine).
2. Run:

```bash
rm -rf ~/avatar-face
bash bootstrap.sh ~/avatar-face
cd ~/avatar-face
git push -u origin main
bash install.sh
```

### Option 2 — Tarball

```bash
rm -rf ~/avatar-face
mkdir -p ~/avatar-face
tar -xzf avatar-face-*.tar.gz -C ~/avatar-face
cd ~/avatar-face
git init && git branch -M main
git remote add origin https://github.com/niks12/avatar-face.git
git add . && git commit -m "Initial commit: AvatarFace for YouTube Shorts and Reels"
git push -u origin main
bash install.sh
```

### Option 3 — Clone after the first push

Once the repo has code on GitHub:

```bash
git clone https://github.com/niks12/avatar-face.git ~/avatar-face
cd ~/avatar-face
bash install.sh
```

Private repo is fine — use a [Personal Access Token](https://github.com/settings/tokens) (scope: `repo`) when Git asks for a password.

## Indian accent virtual host

AvatarFace includes an **original fictional** Indian-style host (not a celebrity likeness).

```bash
python create_indian_host_face.py
cp config.env.example config.env   # uses en-IN-NeerjaNeural + indian-host-face.png
./automate.sh file scripts/examples/indian-host-short.txt
```

**Indian English voices:** `en-IN-NeerjaNeural`, `en-IN-PrabhatNeural`  
**Hindi voices:** `hi-IN-SwaraNeural`, `hi-IN-MadhurNeural`

> Do not use real celebrity faces (actors/actresses) without permission. YouTube may remove deepfake or misleading content. Use original art, your own photo, or licensed stock images instead.

## Quick start (Ubuntu laptop)

```bash
cd ~/avatar-face
bash install.sh
xdg-open output/install-test.mp4
```

`install.sh` installs `ffmpeg`, Python dependencies, creates a sample face, and generates a test short.

## Daily automation

```bash
cd ~/avatar-face
./automate.sh one "Your script here"
./automate.sh batch
xdg-open output/*.mp4
```

| Command | What it does |
|---------|----------------|
| `./automate.sh install` | First-time setup |
| `./automate.sh one "text"` | One short instantly |
| `./automate.sh batch` | All scripts in `inbox/` |
| `./automate.sh watch` | Auto-generate when files land in `inbox/` |
| `./automate.sh status` | Show your settings |

### Your face and voice

```bash
cp config.env.example config.env
nano config.env
```

Set `AVATAR_IMAGE="/home/you/Pictures/my-face.jpg"` and pick a voice.

### Batch from script files

```bash
cp scripts/examples/*.txt inbox/
./automate.sh batch
```

Script format:

```text
---
title: My Hook
voice: en-US-GuyNeural
rate: +5%
---
This is what the avatar says in the video.
```

## Copy to your laptop

**Option A — USB / scp / cloud drive**

Copy the whole `avatar-face` folder to `~/avatar-face`, then:

```bash
cd ~/avatar-face
bash install.sh
```

**Option B — tarball**

On a machine that has the project:

```bash
bash package-for-laptop.sh
# copies avatar-face-YYYYMMDD.tar.gz to your home folder
```

On the laptop:

```bash
mkdir -p ~/avatar-face
tar -xzf avatar-face-*.tar.gz -C ~/avatar-face
cd ~/avatar-face
bash install.sh
```

**Option C — own git repo (optional)**

```bash
git clone https://github.com/YOUR_USER/avatar-face.git ~/avatar-face
cd ~/avatar-face
bash install.sh
```

## Engines

| Mode | Command flag | Hardware |
|------|----------------|----------|
| `fast` (default) | `--engine fast` | CPU |
| SadTalker | `--engine sadtalker` | CPU/GPU, run `setup_sadtalker.sh` first |

## Requirements

- Ubuntu 22.04+ (or similar Linux)
- Python 3.10+
- `ffmpeg`
- Internet for text-to-speech (edge-tts)

## Project layout

```
avatar-face/
  install.sh           # start here
  automate.sh          # daily automation
  generate_short.py    # core generator
  config.env.example   # your settings
  inbox/               # drop script .txt files
  output/              # finished MP4s
  assets/              # default face image
  scripts/examples/    # sample scripts
```

## Tips for shorts

1. Keep scripts under 60 seconds.
2. Hook viewers in the first 2 seconds.
3. Add captions in CapCut or YouTube Studio after export.
4. Use the same face + voice for channel branding.
