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

mkdir -p "${ROOT}/shorts/output" 2>/dev/null || mkdir -p "${ROOT}/output"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG}"; }

log "=== mywork update started ==="
log "Folder: ${ROOT}"
log "Branch: ${BRANCH}"

# Safety: do not pull limagica main into a mywork folder
if [[ -d "${ROOT}/.git" ]]; then
  ORIGIN_URL="$(git -C "${ROOT}" remote get-url origin 2>/dev/null || true)"
  if [[ "${ORIGIN_URL}" == *"niks12/mywork"* ]]; then
    log "Pulling latest from niks12/mywork..."
    git -C "${ROOT}" fetch origin
    git -C "${ROOT}" checkout "${BRANCH}"
    git -C "${ROOT}" pull --ff-only origin "${BRANCH}" || log "Git pull skipped"
  elif [[ "${ORIGIN_URL}" == *"niks12/limagica"* ]]; then
    log "WARNING: origin is limagica — NOT pulling (would delete shorts/)."
    log "Run: git checkout export/mywork-full-0966"
    log "Then: bash push-to-github.sh"
    if [[ ! -f "${ROOT}/shorts/install.sh" ]]; then
      log "Restoring Priya project files from export branch..."
      git -C "${ROOT}" fetch origin
      git -C "${ROOT}" checkout export/mywork-full-0966
    fi
  else
    log "Unknown origin — skip git pull"
  fi
else
  log "Not a git repo — skip pull"
fi

if [[ ! -f "${ROOT}/shorts/generate_short.py" ]]; then
  echo
  echo "ERROR: shorts/ folder missing. This is not the Priya mywork project."
  echo
  echo "Fix:"
  echo "  cd ~ && rm -rf mywork-full"
  echo "  export GITHUB_TOKEN='ghp_your_token'"
  echo "  git clone -b export/mywork-full-0966 \\"
  echo "    \"https://\${GITHUB_TOKEN}@github.com/niks12/limagica.git\" mywork-full"
  echo "  cd mywork-full && bash push-to-github.sh"
  exit 1
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
if [[ -f "${ROOT}/shorts/install.sh" ]]; then
  bash "${ROOT}/shorts/install.sh"
elif [[ -f "${ROOT}/shorts/install-ubuntu.sh" ]]; then
  bash "${ROOT}/shorts/install-ubuntu.sh"
else
  echo "ERROR: shorts/install.sh not found" >&2
  exit 1
fi

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
echo
echo "Play test: xdg-open ${ROOT}/shorts/output/update-test.mp4"
