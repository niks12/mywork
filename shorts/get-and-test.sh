#!/usr/bin/env bash
# First-time setup on laptop: clone repo + run full test.
# Usage:
#   bash get-and-test.sh
#
# Or if repo is private, set GITHUB_TOKEN first:
#   export GITHUB_TOKEN=your_token
#   bash get-and-test.sh
set -euo pipefail

REPO="https://github.com/niks12/avatar-face.git"
INSTALL_DIR="${HOME}/avatar-face"

echo "==> AvatarFace — clone and test on laptop"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  REPO="https://${GITHUB_TOKEN}@github.com/niks12/avatar-face.git"
fi

if [[ -d "${INSTALL_DIR}/.git" ]]; then
  echo "==> Updating existing ${INSTALL_DIR}"
  git -C "${INSTALL_DIR}" pull --ff-only || true
else
  echo "==> Cloning to ${INSTALL_DIR}"
  git clone "${REPO}" "${INSTALL_DIR}"
fi

cd "${INSTALL_DIR}"
chmod +x test-on-laptop.sh install-full-auto.sh auto-pilot.sh run.sh 2>/dev/null || true
bash test-on-laptop.sh
