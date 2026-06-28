# Full automation — zero manual copying

Run **one command once**. After that, videos are created automatically.

## One command setup

```bash
cd ~/avatar-face
bash install-full-auto.sh
```

That's it. No copying scripts. No daily commands.

## What runs automatically

| When | What happens |
|------|----------------|
| **Right after install** | Creates face + makes videos immediately |
| **Every day at 9 AM** | Picks a topic → writes script → makes Short |
| **On login** | Catches up if a run was missed |
| **Git pull** | Gets new topics/scripts from your repo |

Videos save to: `output/`  
Log file: `output/automation.log`

## Customize topics (optional, one time)

Edit `scripts/topics.txt` — one topic per line:

```bash
nano ~/avatar-face/scripts/topics.txt
```

Example:
```
YouTube growth tips
Daily motivation
Tech hack of the day
```

The system picks a topic, writes the script, and makes the video. **You never touch inbox/.**

## Add your own scripts (optional)

Drop files in `scripts/queue/` (or commit to git). They are processed automatically once.

## Check it is working

```bash
tail -f ~/avatar-face/output/automation.log
ls -lt ~/avatar-face/output/*.mp4
systemctl --user status avatar-face.timer
```

## Run manually anytime

```bash
~/avatar-face/auto-pilot.sh
```

## Turn off automation

```bash
~/avatar-face/setup-automation.sh --remove
```

## After git clone on a new laptop

```bash
git clone https://github.com/niks12/avatar-face.git ~/avatar-face
cd ~/avatar-face
bash install-full-auto.sh
```

Only **one command** needed on each machine.

## Test on your laptop

Quick test (repo already cloned):

```bash
cd ~/avatar-face
bash test-on-laptop.sh
```

First time — clone + test in one go:

```bash
bash get-and-test.sh
```

Or step by step:

```bash
git clone https://github.com/niks12/avatar-face.git ~/avatar-face
cd ~/avatar-face
bash test-on-laptop.sh
```

The test script checks python/ffmpeg, creates a test Short, verifies 1080x1920, and opens the video.
