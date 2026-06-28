#!/usr/bin/env bash
# AvatarFace — one command to make YouTube Shorts.
#
# Usage:
#   ./run.sh                         # process all scripts in inbox/
#   ./run.sh "Your spoken script"    # make one short now
#   ./run.sh --watch                 # auto-make when you drop files in inbox/
#   ./run.sh --setup                 # install + configure automation
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

run_setup() {
  exec bash "${ROOT}/install-full-auto.sh"
}

case "${1:-}" in
  --setup|-s)
    run_setup
    ;;
  --watch|-w)
    exec "${ROOT}/automate.sh" watch
    ;;
  --batch|-b|"")
    exec "${ROOT}/automate.sh" batch
    ;;
  --help|-h)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    echo
    "${ROOT}/automate.sh" help
    ;;
  *)
    title="Short"
    text="$*"
    exec "${ROOT}/automate.sh" one "${text}" "${title}"
    ;;
esac
