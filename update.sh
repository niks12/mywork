#!/usr/bin/env bash
# Update mywork (Priya news avatar) on your laptop — run anytime.
#
# Usage:
#   cd ~/mywork
#   bash update.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="${MYWORK_BRANCH:-main}"
LOG="${ROOT}/shorts/output/update.log"

mkdir -p "${ROOT}/shorts/output"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG}"; }

log "=== mywork update started ==="
log "Folder: ${ROOT}"
log "Branch: ${BRANCH}"

if [[ -d "${ROOT}/.git" ]]; then
  log "Pulling latest from GitHub..."
  git -C "${ROOT}" fetch origin
  git -C "${ROOT}" checkout "${BRANCH}"
  git -C "${ROOT}" pull --ff-only origin "${BRANCH}" || log "Git pull skipped (check network/auth)"
else
  log "Not a git repo — skip pull"
fi

# System deps
missing=()
command -v python3 >/dev/null || missing+=("python3")
command -v ffmpeg >/dev/null || missing+=("ffmpeg")
if ((${#missing[@]})); then
  log "Installing: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y python3 python3-venv python3-pip ffmpeg git
fi

log "Updating Python environment..."
bash "${ROOT}/shorts/install.sh"

[[ -f "${ROOT}/shorts/config.env" ]] || cp "${ROOT}/shorts/config.env.example" "${ROOT}/shorts/config.env"

log "Regenerating Priya news assets..."
# shellcheck disable=SC1091
source "${ROOT}/shorts/.venv/bin/activate"
python "${ROOT}/shorts/create_news_assets.py"

log "Syncing avatar to public web UI..."
mkdir -p "${ROOT}/public/avatars/priya/assets"
cp "${ROOT}/avatars/priya/assets/avatar-news.png" "${ROOT}/public/avatars/priya/assets/"
cp "${ROOT}/avatars/priya/assets/avatar.png" "${ROOT}/public/avatars/priya/assets/" 2>/dev/null || true

log "Running quick news test short..."
python "${ROOT}/shorts/generate_short.py" \
  --style newsroom \
  --image "${ROOT}/avatars/priya/assets/avatar-news.png" \
  --background "${ROOT}/shorts/assets/newsroom-background.png" \
  --voice en-IN-NeerjaNeural \
  --title "Priya News Test" \
  --ticker "Update successful" \
  --text "Namaste. This is Priya with your news update. Subscribe for daily Shorts." \
  --output "${ROOT}/shorts/output/update-test.mp4"

log "=== Update complete ==="
log "Test video: ${ROOT}/shorts/output/update-test.mp4"
log "Full automation: bash ${ROOT}/shorts/install-full-auto.sh"
echo
echo "Play test: xdg-open ${ROOT}/shorts/output/update-test.mp4"
