#!/usr/bin/env bash
# Optional: install SadTalker for photoreal lip-sync (CPU or GPU).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="${ROOT}/vendor/SadTalker"

if [[ -d "${VENDOR}/.git" ]]; then
  echo "SadTalker already cloned at ${VENDOR}"
else
  mkdir -p "${ROOT}/vendor"
  git clone --depth 1 https://github.com/OpenTalker/SadTalker.git "${VENDOR}"
fi

python3 -m venv "${ROOT}/.venv-sadtalker"
# shellcheck disable=SC1091
source "${ROOT}/.venv-sadtalker/bin/activate"
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install -r "${VENDOR}/requirements.txt"

if [[ ! -f "${VENDOR}/scripts/download_models.sh" ]]; then
  echo "Could not find SadTalker model download script."
  exit 1
fi

bash "${VENDOR}/scripts/download_models.sh"

echo
echo "SadTalker is ready. Generate a high-quality short with:"
echo "  source ${ROOT}/.venv/bin/activate"
echo "  python ${ROOT}/generate_short.py --engine sadtalker --text 'Your script' --image path/to/face.jpg"
