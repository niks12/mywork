#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLIC_DIR="${ROOT_DIR}/public"
AVATAR_SRC="${ROOT_DIR}/avatars/priya"
AVATAR_DEST="${PUBLIC_DIR}/avatars/priya"
PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"

pick_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo python3
    return
  fi

  if command -v python >/dev/null 2>&1; then
    echo python
    return
  fi

  echo ""
}

sync_avatar_assets() {
  if [[ ! -d "${AVATAR_SRC}" ]]; then
    echo "Warning: avatar source not found at ${AVATAR_SRC}"
    return
  fi

  mkdir -p "${AVATAR_DEST}"
  cp -R "${AVATAR_SRC}/." "${AVATAR_DEST}/"
  echo "Synced avatar files to public/avatars/priya/"
}

open_browser() {
  local url="$1"

  if [[ "${OPEN_BROWSER:-1}" == "0" ]]; then
    return
  fi

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 || true
  elif command -v open >/dev/null 2>&1; then
    open "${url}" >/dev/null 2>&1 || true
  fi
}

PYTHON_BIN="$(pick_python)"
if [[ -z "${PYTHON_BIN}" ]]; then
  echo "Error: Python is required. Install Python 3 and try again."
  exit 1
fi

if [[ ! -d "${PUBLIC_DIR}" ]]; then
  echo "Error: public folder not found at ${PUBLIC_DIR}"
  exit 1
fi

sync_avatar_assets

URL="http://${HOST}:${PORT}"

echo
echo "Priya Avatar — local host"
echo "-------------------------"
echo "URL:      ${URL}"
echo "Folder:   ${PUBLIC_DIR}"
echo "Python:   ${PYTHON_BIN}"
echo
echo "Press Ctrl+C to stop the server."
echo

(
  sleep 1
  open_browser "${URL}"
) &

cd "${PUBLIC_DIR}"
exec "${PYTHON_BIN}" -m http.server "${PORT}" --bind "${HOST}"
