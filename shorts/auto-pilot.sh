#!/usr/bin/env bash
# Fully automated AvatarFace — no manual copying required.
#
# Runs daily (or on boot) via systemd:
#   1. Optional git pull for new scripts/topics
#   2. Auto-generate today's script from scripts/topics.txt
#   3. Process scripts/queue/ and inbox/
#   4. Save videos to output/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"
LOG="${ROOT}/output/automation.log"
mkdir -p "${ROOT}/output" "${ROOT}/.state" "${ROOT}/scripts/queue" "${ROOT}/inbox"

# shellcheck disable=SC1091
source "${ROOT}/lib/common.sh"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG}"
}

ensure_ready() {
  if [[ ! -f "${ROOT}/.venv/bin/python" ]]; then
    log "Installing AvatarFace..."
    bash "${ROOT}/install.sh"
  fi
  [[ -f config.env ]] || cp config.env.example config.env
  avatar_load_config "${ROOT}"
  avatar_activate_venv "${ROOT}"

  local image_path
  image_path="$(avatar_resolve_path "${ROOT}" "${AVATAR_IMAGE}")"
  if [[ ! -f "${image_path}" ]]; then
    log "Creating host face..."
    if [[ -f create_indian_host_face.py ]]; then
      python create_indian_host_face.py
    else
      python create_sample_face.py
    fi
  fi
}

maybe_git_pull() {
  if [[ "${AVATAR_AUTO_GIT_PULL:-true}" != "true" ]]; then
    return 0
  fi
  if [[ ! -d .git ]]; then
    return 0
  fi
  log "Pulling latest from git..."
  git pull --ff-only origin main 2>/dev/null || git pull --ff-only 2>/dev/null || log "Git pull skipped"
}

run_auto_pipeline() {
  log "=== Auto-pilot started ==="

  if [[ "${AVATAR_DAILY_TOPIC:-true}" == "true" ]]; then
    log "Generating daily script from topics..."
    python "${ROOT}/generate_daily_script.py" || true
  fi

  log "Processing script queue..."
  python "${ROOT}/process_queue.py"

  local inbox_count
  inbox_count=$(find inbox -maxdepth 1 -type f \( -name '*.txt' -o -name '*.md' \) 2>/dev/null | wc -l)
  if (( inbox_count > 0 )); then
    log "Processing inbox (${inbox_count} files)..."
    "${ROOT}/automate.sh" batch
  fi

  local count
  count=$(find output -maxdepth 1 -name '*.mp4' 2>/dev/null | wc -l)
  log "=== Auto-pilot done. Total videos in output/: ${count} ==="
}

ensure_ready
maybe_git_pull
run_auto_pipeline
