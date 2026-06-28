# mywork

**Priya News** — multilingual virtual news anchor for **YouTube Shorts**.

**Repo:** https://github.com/niks12/mywork  
**Branch:** `main`

| Part | What it does |
|------|----------------|
| `host.sh` | Priya in browser (English / Hindi / Gujarati) |
| `shorts/` | Auto-generate newsroom-style YouTube videos |
| `update.sh` | Pull latest + rebuild news assets + test video |

---

## First time on laptop

```bash
git clone https://github.com/niks12/mywork.git
# OR GitLab:
# git clone https://gitlab.com/niks12/mywork.git
cd mywork
bash update.sh
```

## Push to GitLab (from your machine)

```bash
export GITLAB_TOKEN="glpat-your-token"
export GITLAB_URL="https://gitlab.com"
export GITLAB_PROJECT="niks12/mywork"
cd ~/mywork
bash push-to-gitlab.sh
```

## Update anytime

```bash
cd ~/mywork
bash update.sh
```

## Full daily automation (no manual work)

```bash
cd ~/mywork/shorts
bash install-full-auto.sh
```

Videos save to `shorts/output/` — Priya reads the news with a **studio background**.

---

## Quick test

```bash
cd ~/mywork/shorts
bash test-on-laptop.sh
xdg-open output/laptop-test.mp4
```

## One news Short manually

```bash
cd ~/mywork/shorts
./run.sh "Namaste. This is Priya News with today's top story. Subscribe for daily updates."
```

---

## Priya web avatar

```bash
./host.sh
# Opens http://127.0.0.1:8080
```

See full Linux install steps below.

---
