#!/usr/bin/env bash
# One-command installer for Ubuntu laptop.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

echo "==> AvatarFace — Ubuntu install"
echo "    Directory: ${ROOT}"

missing=()
command -v python3 >/dev/null || missing+=("python3")
command -v ffmpeg >/dev/null || missing+=("ffmpeg")

if ((${#missing[@]})); then
  echo "==> Installing system packages: ${missing[*]} python3-venv python3-pip"
  sudo apt-get update -qq
  sudo apt-get install -y python3 python3-venv python3-pip ffmpeg
fi

if ! python3 -c "import ensurepip" 2>/dev/null; then
  sudo apt-get install -y python3-venv
fi

echo "==> Creating Python virtual environment"
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

if [[ ! -f assets/sample-face.png ]]; then
  echo "==> Creating sample avatar face"
  python create_sample_face.py
fi

mkdir -p output inbox inbox/done scripts/examples

if [[ ! -f config.env ]]; then
  cp config.env.example config.env
  echo "Created config.env — set AVATAR_IMAGE to your photo path."
fi

echo "==> Generating test short (about 6 seconds)"
python generate_short.py \
  --text "Hi! Your virtual face is installed and ready for YouTube Shorts." \
  --title "Install test" \
  --output output/install-test.mp4

cat > avatar-short <<'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/.venv/bin/activate"
exec python "${ROOT}/generate_short.py" "$@"
EOF
chmod +x avatar-short

echo
echo "=============================================="
echo " Install complete!"
echo "=============================================="
echo
echo "Test video:  ${ROOT}/output/install-test.mp4"
echo "Automation:  ${ROOT}/automate.sh batch"
echo "Quick run:   ${ROOT}/automate.sh one 'Hello world'"
echo
echo "Open the test video:"
echo "  xdg-open ${ROOT}/output/install-test.mp4"
