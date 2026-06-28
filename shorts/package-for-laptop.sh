#!/usr/bin/env bash
# Build a tarball to copy to another Ubuntu machine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="avatar-face"
STAMP="$(date +%Y%m%d)"
ARCHIVE="${HOME}/${NAME}-${STAMP}.tar.gz"

cd "${ROOT}"
tar -czf "${ARCHIVE}" \
  --exclude='.venv' \
  --exclude='.venv-sadtalker' \
  --exclude='vendor' \
  --exclude='output' \
  --exclude='config.env' \
  --exclude='inbox/done' \
  --exclude='*.tar.gz' \
  --exclude='.git' \
  .

echo "Created: ${ARCHIVE}"
echo
echo "Copy to laptop:"
echo "  scp ${ARCHIVE} you@laptop:~/"
echo
echo "On laptop:"
echo "  mkdir -p ~/avatar-face"
echo "  tar -xzf ${NAME}-${STAMP}.tar.gz -C ~/avatar-face"
echo "  cd ~/avatar-face && bash install.sh"
