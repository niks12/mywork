#!/usr/bin/env bash
# ONE command — install everything and enable full automation (no manual steps).
#
# Usage:
#   bash install-full-auto.sh
#
# After this, videos are created automatically every day at 9 AM and on login.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

echo "=============================================="
echo " AvatarFace — Full Auto Install"
echo "=============================================="

bash "${ROOT}/install.sh"

[[ -f config.env ]] || cp config.env.example config.env

# Enable full automation flags
if ! grep -q '^AVATAR_AUTO_MODE=' config.env 2>/dev/null; then
  cat >> config.env << 'EOF'

# Full automation (set by install-full-auto.sh)
AVATAR_AUTO_MODE="true"
AVATAR_AUTO_GIT_PULL="true"
AVATAR_DAILY_TOPIC="true"
EOF
fi

chmod +x "${ROOT}/auto-pilot.sh" "${ROOT}/run.sh" "${ROOT}/automate.sh" "${ROOT}/setup-automation.sh"

# shellcheck disable=SC1091
source "${ROOT}/.venv/bin/activate"
python create_news_assets.py
mkdir -p scripts/queue inbox output .state inbox/done

# Seed queue with starter scripts (processed automatically — no inbox copy needed)
cp -n scripts/examples/*.txt scripts/queue/ 2>/dev/null || true

# Run once immediately so user gets videos without doing anything
bash "${ROOT}/auto-pilot.sh"

# Install systemd: daily 9 AM + on boot
bash "${ROOT}/setup-automation.sh" --full-auto

# Keep timers running even when logged out (optional but recommended)
if command -v loginctl >/dev/null && ! loginctl show-user "$(whoami)" -p Linger 2>/dev/null | grep -q yes; then
  echo "==> Enabling linger (auto-run when laptop is on but logged out)..."
  sudo loginctl enable-linger "$(whoami)" 2>/dev/null || echo "    (Skip if sudo not available — timer runs when you are logged in)"
fi

echo
echo "=============================================="
echo " FULL AUTOMATION IS ON"
echo "=============================================="
echo
echo "You do NOT need to copy files manually."
echo
echo "Videos:  ${ROOT}/output/"
echo "Log:     ${ROOT}/output/automation.log"
echo
echo "What happens automatically:"
echo "  - Every day at 9 AM → new Short from scripts/topics.txt"
echo "  - On login/boot       → checks and runs if missed"
echo "  - git pull            → gets new topics/scripts from your repo"
echo
echo "Optional — edit topics (one per line):"
echo "  nano ${ROOT}/scripts/topics.txt"
echo
echo "Check status:"
echo "  systemctl --user status avatar-face.timer"
echo "  tail -f ${ROOT}/output/automation.log"
echo
echo "Run manually anytime:"
echo "  ${ROOT}/auto-pilot.sh"
