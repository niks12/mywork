#!/usr/bin/env bash
# Test AvatarFace on your Ubuntu laptop — one script, full check.
#
# Usage:
#   cd ~/avatar-face
#   bash test-on-laptop.sh
#
# Or download and run (after git clone):
#   git clone https://github.com/niks12/avatar-face.git ~/avatar-face
#   cd ~/avatar-face
#   bash test-on-laptop.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

PASS=0
FAIL=0

ok()   { echo "  [OK]   $*"; PASS=$((PASS + 1)); }
bad()  { echo "  [FAIL] $*"; FAIL=$((FAIL + 1)); }
step() { echo; echo "==> $*"; }

step "AvatarFace laptop test"
echo "    Folder: ${ROOT}"

# --- 1. System checks ---
step "1/6 System dependencies"

if command -v python3 >/dev/null; then
  ok "python3: $(python3 --version 2>&1)"
else
  bad "python3 not found — run: sudo apt install python3 python3-venv"
fi

if command -v ffmpeg >/dev/null; then
  ok "ffmpeg: $(ffmpeg -version 2>&1 | head -1)"
else
  bad "ffmpeg not found — run: sudo apt install ffmpeg"
fi

if command -v git >/dev/null; then
  ok "git installed"
else
  bad "git not found (optional but recommended)"
fi

if (( FAIL > 0 )); then
  echo
  echo "Fix missing packages then run this script again."
  exit 1
fi

# --- 2. Install if needed ---
step "2/6 Python environment"

if [[ ! -f "${ROOT}/.venv/bin/python" ]]; then
  echo "    Installing (first time only)..."
  bash "${ROOT}/install.sh"
else
  ok "Virtual environment exists"
fi

# shellcheck disable=SC1091
source "${ROOT}/.venv/bin/activate"

[[ -f config.env ]] || cp config.env.example config.env
ok "config.env ready"

# --- 3. Face image ---
step "3/6 Host face image"

if [[ -f assets/indian-host-face.png ]]; then
  ok "indian-host-face.png exists"
else
  echo "    Creating host face..."
  python create_indian_host_face.py
  ok "Created assets/indian-host-face.png"
fi

# --- 4. Quick TTS + video test ---
step "4/6 Generate test short (about 10 seconds)"

mkdir -p output inbox scripts/queue .state

TEST_OUT="${ROOT}/output/laptop-test.mp4"
TEST_TEXT="Namaste! This is a laptop test. AvatarFace is working correctly on your computer."

rm -f "${TEST_OUT}" "${TEST_OUT%.mp4}.json"

python generate_short.py \
  --image assets/indian-host-face.png \
  --voice en-IN-NeerjaNeural \
  --text "${TEST_TEXT}" \
  --title "Laptop Test" \
  --output "${TEST_OUT}"

if [[ -f "${TEST_OUT}" ]]; then
  SIZE=$(du -h "${TEST_OUT}" | cut -f1)
  ok "Video created: ${TEST_OUT} (${SIZE})"
else
  bad "Video was not created"
  exit 1
fi

# --- 5. Verify video format ---
step "5/6 Verify video (9:16 for Shorts)"

if command -v ffprobe >/dev/null; then
  W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "${TEST_OUT}")
  H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "${TEST_OUT}")
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${TEST_OUT}")
  if [[ "${W}" == "1080" && "${H}" == "1920" ]]; then
    ok "Resolution: ${W}x${H} (correct for Shorts/Reels)"
  else
    bad "Resolution: ${W}x${H} (expected 1080x1920)"
  fi
  ok "Duration: ${D}s"
else
  ok "ffprobe skipped"
fi

# --- 6. Auto-pilot smoke test ---
step "6/6 Auto-pilot smoke test"

python generate_daily_script.py >/dev/null 2>&1 || true
if python process_queue.py 2>&1 | tail -3; then
  ok "Auto-pilot scripts run"
else
  bad "Auto-pilot failed"
fi

# --- Summary ---
echo
echo "=============================================="
if (( FAIL == 0 )); then
  echo " ALL TESTS PASSED (${PASS} checks)"
else
  echo " SOME TESTS FAILED (ok=${PASS} fail=${FAIL})"
fi
echo "=============================================="
echo
echo "Test video: ${TEST_OUT}"
echo
echo "Play it:"
echo "  xdg-open ${TEST_OUT}"
echo
echo "Enable full daily automation:"
echo "  bash install-full-auto.sh"
echo
echo "All output videos:"
echo "  ls -lt ${ROOT}/output/*.mp4"

if command -v xdg-open >/dev/null; then
  read -r -p "Open test video now? [Y/n] " ans
  if [[ -z "${ans}" || "${ans}" =~ ^[Yy]$ ]]; then
    xdg-open "${TEST_OUT}" >/dev/null 2>&1 &
    ok "Opened video player"
  fi
fi

exit "${FAIL}"
