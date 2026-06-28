#!/usr/bin/env bash
# Shared helpers for avatar-shorts automation.
set -euo pipefail

avatar_root() {
  cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd
}

avatar_load_config() {
  local root="$1"
  if [[ -f "${root}/config.env" ]]; then
    # shellcheck disable=SC1091
    source "${root}/config.env"
  elif [[ -f "${root}/config.env.example" ]]; then
    # shellcheck disable=SC1091
    source "${root}/config.env.example"
  fi

  : "${AVATAR_IMAGE:=../avatars/priya/assets/avatar-news.png}"
  : "${AVATAR_VOICE:=en-IN-NeerjaNeural}"
  : "${AVATAR_RATE:=+0%}"
  : "${AVATAR_ENGINE:=fast}"
  : "${AVATAR_STYLE:=newsroom}"
  : "${AVATAR_BACKGROUND:=assets/newsroom-background.png}"
  : "${AVATAR_OPEN_VIDEO:=false}"
  : "${AVATAR_STYLE:=newsroom}"
  : "${AVATAR_BACKGROUND:=assets/newsroom-background.png}"
  : "${AVATAR_INBOX:=inbox}"
  : "${AVATAR_OUTPUT:=output}"
  : "${AVATAR_DONE:=inbox/done}"
}

avatar_activate_venv() {
  local root="$1"
  if [[ ! -f "${root}/.venv/bin/activate" ]]; then
    echo "Virtual env missing. Run: bash ${root}/install-ubuntu.sh" >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source "${root}/.venv/bin/activate"
}

avatar_slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

avatar_timestamp() {
  date +%Y%m%d-%H%M%S
}

avatar_resolve_path() {
  local root="$1"
  local path="$2"
  if [[ "${path}" = /* ]]; then
    echo "${path}"
  else
    echo "${root}/${path}"
  fi
}

avatar_open_video() {
  local path="$1"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${path}" >/dev/null 2>&1 &
  fi
}

# Parse script file with optional YAML-like frontmatter.
# Sets: SCRIPT_TITLE SCRIPT_VOICE SCRIPT_RATE SCRIPT_TEXT
avatar_parse_script_file() {
  local file="$1"
  local base
  base="$(basename "${file}" .txt)"
  base="$(basename "${base}" .md)"

  SCRIPT_TITLE=""
  SCRIPT_VOICE=""
  SCRIPT_RATE=""
  SCRIPT_TEXT=""

  if grep -q '^---$' "${file}"; then
    local front body
    front="$(awk 'BEGIN{p=0} /^---$/{p++; next} p==1{print} p==2{exit}' "${file}")"
    body="$(awk 'BEGIN{p=0} /^---$/{p++; next} p>=2{print}' "${file}")"

    while IFS=': ' read -r key value; do
      [[ -z "${key}" ]] && continue
      value="${value//$'\r'/}"
      case "${key}" in
        title) SCRIPT_TITLE="${value}" ;;
        voice) SCRIPT_VOICE="${value}" ;;
        rate) SCRIPT_RATE="${value}" ;;
      esac
    done <<< "${front}"

    SCRIPT_TEXT="$(echo "${body}" | sed '/./,$!d')"
  else
    SCRIPT_TEXT="$(cat "${file}")"
  fi

  SCRIPT_TEXT="$(echo "${SCRIPT_TEXT}" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"
  if [[ -z "${SCRIPT_TITLE}" ]]; then
    SCRIPT_TITLE="$(echo "${base}" | tr '-' ' ' | tr '_' ' ' | sed -E 's/\b(.)/\u\1/g')"
  fi
}

avatar_generate_short() {
  local root="$1"
  local text="$2"
  local title="$3"
  local output="$4"
  local image="$5"
  local voice="$6"
  local rate="$7"
  local engine="$8"
  local style="${9:-newsroom}"
  local background="${10:-assets/newsroom-background.png}"

  mkdir -p "$(dirname "${output}")"

  local image_path="$image"
  local bg_path
  bg_path="$(avatar_resolve_path "${root}" "${background}")"

  local -a cmd=(
    python "${root}/generate_short.py"
    --text "${text}"
    --title "${title}"
    --output "${output}"
    --image "${image_path}"
    --voice "${voice}"
    --rate "${rate}"
    --engine "${engine}"
    --style "${style}"
  )
  if [[ "${style}" == "newsroom" ]]; then
    cmd+=(--background "${bg_path}")
    cmd+=(--ticker "${title}")
  fi

  echo "==> Generating: ${output}"
  "${cmd[@]}"
  echo "==> Done: ${output}"
}
