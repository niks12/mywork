#!/usr/bin/env bash
# Install scheduled automation for AvatarFace on Ubuntu.
#
# Usage:
#   ./setup-automation.sh           # interactive menu
#   ./setup-automation.sh --cron    # daily batch at 9:00 AM
#   ./setup-automation.sh --systemd # systemd user timer (recommended)
#   ./setup-automation.sh --remove  # remove cron + systemd timers
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_TAG="# avatar-face-automation"
CRON_LINE="0 9 * * * cd ${ROOT} && ${ROOT}/run.sh --batch >> ${ROOT}/output/automation.log 2>&1 ${CRON_TAG}"

install_cron() {
  mkdir -p "${ROOT}/output"
  local tmp existing
  tmp="$(mktemp)"
  existing="$(crontab -l 2>/dev/null | grep -v "${CRON_TAG}" || true)"
  {
    echo "${existing}"
    echo "${CRON_LINE}"
  } | sed '/^$/d' | crontab -
  echo "==> Cron installed: daily batch at 9:00 AM"
  echo "    Log: ${ROOT}/output/automation.log"
  echo "    Edit: crontab -e"
}

install_systemd() {
  mkdir -p "${HOME}/.config/systemd/user" "${ROOT}/output"
  cat > "${HOME}/.config/systemd/user/avatar-face.service" << EOF
[Unit]
Description=AvatarFace batch short generator
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${ROOT}
ExecStart=${ROOT}/run.sh --batch
StandardOutput=append:${ROOT}/output/automation.log
StandardError=append:${ROOT}/output/automation.log

[Install]
WantedBy=default.target
EOF

  cat > "${HOME}/.config/systemd/user/avatar-face.timer" << EOF
[Unit]
Description=Daily AvatarFace batch at 9:00 AM

[Timer]
OnCalendar=*-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now avatar-face.timer
  echo "==> Systemd timer installed: daily 9:00 AM"
  echo "    Status: systemctl --user status avatar-face.timer"
  echo "    Log:    ${ROOT}/output/automation.log"
  echo "    Run now: systemctl --user start avatar-face.service"
}

install_full_auto() {
  mkdir -p "${HOME}/.config/systemd/user" "${ROOT}/output" "${ROOT}/.state"
  cat > "${HOME}/.config/systemd/user/avatar-face.service" << EOF
[Unit]
Description=AvatarFace full auto-pilot (generate + render Shorts)
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${ROOT}
ExecStart=${ROOT}/auto-pilot.sh
StandardOutput=append:${ROOT}/output/automation.log
StandardError=append:${ROOT}/output/automation.log

[Install]
WantedBy=default.target
EOF

  cat > "${HOME}/.config/systemd/user/avatar-face.timer" << EOF
[Unit]
Description=AvatarFace daily auto at 9:00 AM

[Timer]
OnCalendar=*-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  cat > "${HOME}/.config/systemd/user/avatar-face-boot.service" << EOF
[Unit]
Description=AvatarFace auto-run on login (catch up missed runs)
After=default.target

[Service]
Type=oneshot
WorkingDirectory=${ROOT}
ExecStart=${ROOT}/auto-pilot.sh
StandardOutput=append:${ROOT}/output/automation.log
StandardError=append:${ROOT}/output/automation.log
EOF

  mkdir -p "${HOME}/.config/systemd/user/default.target.wants"
  ln -sf "${HOME}/.config/systemd/user/avatar-face-boot.service" \
    "${HOME}/.config/systemd/user/default.target.wants/avatar-face-boot.service"

  systemctl --user daemon-reload
  systemctl --user enable --now avatar-face.timer
  echo "==> Full automation enabled"
  echo "    Daily timer: 9:00 AM"
  echo "    On login:    auto-pilot runs"
  echo "    Log:         ${ROOT}/output/automation.log"
  echo "    Run now:     systemctl --user start avatar-face.service"
}

remove_automation() {
  crontab -l 2>/dev/null | grep -v "${CRON_TAG}" | crontab - 2>/dev/null || true
  systemctl --user disable --now avatar-face.timer 2>/dev/null || true
  rm -f "${HOME}/.config/systemd/user/default.target.wants/avatar-face-boot.service"
  rm -f "${HOME}/.config/systemd/user/avatar-face-boot.service" \
        "${HOME}/.config/systemd/user/avatar-face.service" \
        "${HOME}/.config/systemd/user/avatar-face.timer"
  systemctl --user daemon-reload 2>/dev/null || true
  echo "==> Removed cron and systemd automation"
}

menu() {
  echo "AvatarFace automation setup"
  echo "  1) Cron — daily 9 AM batch"
  echo "  2) Systemd timer — daily 9 AM batch (recommended)"
  echo "  3) Remove automation"
  echo "  4) Exit"
  read -r -p "Choose [1-4]: " choice
  case "${choice}" in
    1) install_cron ;;
    2) install_systemd ;;
    3) remove_automation ;;
    *) echo "No changes." ;;
  esac
}

case "${1:-}" in
  --cron) install_cron ;;
  --systemd) install_systemd ;;
  --full-auto) install_full_auto ;;
  --remove) remove_automation ;;
  "") menu ;;
  *)
    echo "Unknown option: $1" >&2
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
