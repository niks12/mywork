#!/usr/bin/env bash
# Local automation for AvatarFace on Ubuntu.
#
# Usage:
#   ./automate.sh install              # first-time setup
#   ./automate.sh one "Your script"    # single short from text
#   ./automate.sh file inbox/my.txt    # short from script file
#   ./automate.sh batch                # process all inbox/*.txt
#   ./automate.sh daily                # create face if needed + batch inbox
#   ./automate.sh watch                # auto-generate when files land in inbox/
#   ./automate.sh voices               # list TTS voices
#   ./automate.sh status               # show config and folders
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/lib/common.sh"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  echo
  echo "Script file format (optional frontmatter):"
  cat <<'EOF'

---
title: My Hook Line
voice: en-US-GuyNeural
rate: +5%
---
Hey everyone! This is the spoken script for the short.

EOF
}

cmd_install() {
  bash "${ROOT}/install-ubuntu.sh"
  if [[ ! -f "${ROOT}/config.env" ]]; then
    cp "${ROOT}/config.env.example" "${ROOT}/config.env"
    echo "Created ${ROOT}/config.env — edit AVATAR_IMAGE for your face photo."
  fi
  mkdir -p "${ROOT}/inbox" "${ROOT}/inbox/done" "${ROOT}/output"
}

cmd_status() {
  avatar_load_config "${ROOT}"
  echo "AvatarFace — status"
  echo "  Root:    ${ROOT}"
  echo "  Image:   $(avatar_resolve_path "${ROOT}" "${AVATAR_IMAGE}")"
  echo "  Voice:   ${AVATAR_VOICE}"
  echo "  Rate:    ${AVATAR_RATE}"
  echo "  Engine:  ${AVATAR_ENGINE}"
  echo "  Inbox:   $(avatar_resolve_path "${ROOT}" "${AVATAR_INBOX}")"
  echo "  Output:  $(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")"
  echo "  Done:    $(avatar_resolve_path "${ROOT}" "${AVATAR_DONE}")"
  if [[ -f "${ROOT}/.venv/bin/python" ]]; then
    echo "  Venv:    ready"
  else
    echo "  Venv:    missing (run ./automate.sh install)"
  fi
  echo
  echo "Inbox files:"
  find "$(avatar_resolve_path "${ROOT}" "${AVATAR_INBOX}")" -maxdepth 1 -type f \( -name '*.txt' -o -name '*.md' \) 2>/dev/null | sort || true
}

cmd_voices() {
  avatar_activate_venv "${ROOT}"
  python "${ROOT}/generate_short.py" --list-voices
}

cmd_one() {
  local text="${1:-}"
  local title="${2:-Short}"
  local output="${3:-}"

  if [[ -z "${text}" ]]; then
    echo "Usage: ./automate.sh one \"Your script text\" [title] [output.mp4]" >&2
    exit 1
  fi

  avatar_load_config "${ROOT}"
  avatar_activate_venv "${ROOT}"

  local image output_path
  image="$(avatar_resolve_path "${ROOT}" "${AVATAR_IMAGE}")"
  if [[ -z "${output}" ]]; then
    output_path="$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")/$(avatar_timestamp)-$(avatar_slugify "${title}").mp4"
  else
    output_path="$(avatar_resolve_path "${ROOT}" "${output}")"
  fi

  avatar_generate_short "${ROOT}" "${text}" "${title}" "${output_path}" "${image}" "${AVATAR_VOICE}" "${AVATAR_RATE}" "${AVATAR_ENGINE}" "${AVATAR_STYLE}" "${AVATAR_BACKGROUND}"

  if [[ "${AVATAR_OPEN_VIDEO}" == "true" ]]; then
    avatar_open_video "${output_path}"
  fi
}

process_script_file() {
  local file="$1"
  local move_when_done="${2:-true}"

  avatar_load_config "${ROOT}"
  avatar_activate_venv "${ROOT}"

  avatar_parse_script_file "${file}"

  if [[ -z "${SCRIPT_TEXT}" ]]; then
    echo "Skipping empty script: ${file}" >&2
    return 0
  fi

  local voice="${SCRIPT_VOICE:-${AVATAR_VOICE}}"
  local rate="${SCRIPT_RATE:-${AVATAR_RATE}}"
  local image
  image="$(avatar_resolve_path "${ROOT}" "${AVATAR_IMAGE}")"
  local slug
  slug="$(avatar_slugify "$(basename "${file}" .txt)")"
  slug="$(avatar_slugify "${slug}")"
  local output_path
  output_path="$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")/$(avatar_timestamp)-${slug}.mp4"

  avatar_generate_short "${ROOT}" "${SCRIPT_TEXT}" "${SCRIPT_TITLE}" "${output_path}" "${image}" "${voice}" "${rate}" "${AVATAR_ENGINE}" "${AVATAR_STYLE:-newsroom}" "${AVATAR_BACKGROUND:-assets/newsroom-background.png}"

  if [[ "${AVATAR_OPEN_VIDEO}" == "true" ]]; then
    avatar_open_video "${output_path}"
  fi

  if [[ "${move_when_done}" == "true" ]]; then
    local done_dir
    done_dir="$(avatar_resolve_path "${ROOT}" "${AVATAR_DONE}")"
    mkdir -p "${done_dir}"
    mv "${file}" "${done_dir}/"
    echo "==> Archived script to ${done_dir}/$(basename "${file}")"
  fi
}

cmd_file() {
  local file="${1:-}"
  if [[ -z "${file}" ]] || [[ ! -f "${file}" ]]; then
    echo "Usage: ./automate.sh file inbox/my-script.txt" >&2
    exit 1
  fi
  process_script_file "${file}" "false"
}

cmd_batch() {
  avatar_load_config "${ROOT}"
  local inbox
  inbox="$(avatar_resolve_path "${ROOT}" "${AVATAR_INBOX}")"
  mkdir -p "${inbox}" "$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")" "$(avatar_resolve_path "${ROOT}" "${AVATAR_DONE}")"

  shopt -s nullglob
  local files=("${inbox}"/*.txt "${inbox}"/*.md)
  shopt -u nullglob

  if ((${#files[@]} == 0)); then
    echo "No scripts in ${inbox}/"
    echo "Add a .txt file, for example:"
    echo "  cp scripts/examples/daily-tip.txt inbox/"
    exit 0
  fi

  local f
  for f in "${files[@]}"; do
    process_script_file "${f}" "true"
  done
  echo "==> Batch complete. Videos are in $(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")/"
}

cmd_daily() {
  avatar_load_config "${ROOT}"
  mkdir -p "$(avatar_resolve_path "${ROOT}" "${AVATAR_INBOX}")" \
           "$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")" \
           "$(avatar_resolve_path "${ROOT}" "${AVATAR_DONE}")"

  if [[ ! -f "$(avatar_resolve_path "${ROOT}" "${AVATAR_IMAGE}")" ]]; then
  echo "==> Creating default host face..."
    if [[ -f "${ROOT}/create_indian_host_face.py" ]]; then
      avatar_activate_venv "${ROOT}"
      python "${ROOT}/create_indian_host_face.py"
    else
      avatar_activate_venv "${ROOT}"
      python "${ROOT}/create_sample_face.py"
    fi
  fi

  cmd_batch
  local latest
  latest="$(find "$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")" -name '*.mp4' -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)"
  if [[ -n "${latest}" ]]; then
    echo "==> Latest video: ${latest}"
    if [[ "${AVATAR_OPEN_VIDEO}" == "true" ]]; then
      avatar_open_video "${latest}"
    fi
  fi
}

cmd_watch() {
  avatar_load_config "${ROOT}"
  local inbox
  inbox="$(avatar_resolve_path "${ROOT}" "${AVATAR_INBOX}")"
  mkdir -p "${inbox}" "$(avatar_resolve_path "${ROOT}" "${AVATAR_OUTPUT}")" "$(avatar_resolve_path "${ROOT}" "${AVATAR_DONE}")"

  if ! command -v inotifywait >/dev/null; then
    echo "Installing inotify-tools for folder watch..."
    sudo apt-get update -qq
    sudo apt-get install -y inotify-tools
  fi

  echo "Watching ${inbox}/ for new .txt and .md files..."
  echo "Drop a script file into inbox/ and it will auto-generate."
  echo "Press Ctrl+C to stop."

  while true; do
    inotifywait -e close_write -e moved_to --format '%f' "${inbox}" | while read -r name; do
      case "${name}" in
        *.txt|*.md)
          sleep 0.5
          if [[ -f "${inbox}/${name}" ]]; then
            process_script_file "${inbox}/${name}" "true" || true
          fi
          ;;
      esac
    done
  done
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "${cmd}" in
    install) cmd_install "$@" ;;
    status) cmd_status "$@" ;;
    voices) cmd_voices "$@" ;;
    one) cmd_one "$@" ;;
    file) cmd_file "$@" ;;
    batch) cmd_batch "$@" ;;
    daily) cmd_daily "$@" ;;
    watch) cmd_watch "$@" ;;
    help|-h|--help) usage ;;
    *)
      echo "Unknown command: ${cmd}" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
