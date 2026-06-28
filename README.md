# mywork — Priya News

**GitHub:** https://github.com/niks12/mywork  
**Branch:** `main`

Multilingual news anchor (English / Hindi / Gujarati) + automated **YouTube Shorts** with newsroom background.

| Script | What it does |
|--------|----------------|
| `bash update.sh` | Pull latest + install + test video |
| `bash push-to-github.sh` | Push everything to GitHub main |
| `cd shorts && bash install-full-auto.sh` | Daily auto Shorts |

---

## First time on laptop

```bash
git clone https://github.com/niks12/mywork.git
cd mywork
bash update.sh
```

## If folder is empty after clone

GitHub `main` may be empty until first push. Run:

```bash
git fetch origin
git checkout cursor/female-multilingual-avatar-d1ec
ls -la
```

Then push to main (see below).

---

## Push to GitHub main (one time)

```bash
cd ~/mywork
export GITHUB_TOKEN="ghp_YOUR_TOKEN"
bash push-to-github.sh
```

Create token: https://github.com/settings/tokens → **repo** scope.

---

## Test

```bash
cd ~/mywork/shorts
bash test-on-laptop.sh
xdg-open output/laptop-test.mp4
```

## Priya in browser

```bash
cd ~/mywork
./host.sh
```

---
