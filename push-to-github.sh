#!/usr/bin/env bash
# Push full Priya News project to GitHub niks12/mywork main.
#
# Usage:
#   export GITHUB_TOKEN="ghp_your_token"
#   bash push-to-github.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

MYWORK_REPO="niks12/mywork"
BRANCH="main"

echo "==> Push Priya News to https://github.com/${MYWORK_REPO} (${BRANCH})"

if [[ ! -f "${ROOT}/shorts/generate_short.py" ]]; then
  echo "ERROR: shorts/ missing. Run first:"
  echo "  git checkout export/mywork-full-0966"
  exit 1
fi

rm -rf shorts/.venv shorts/output shorts/.state 2>/dev/null || true

# Auth
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  MYWORK_URL="https://${GITHUB_TOKEN}@github.com/${MYWORK_REPO}.git"
elif command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  MYWORK_URL="https://github.com/${MYWORK_REPO}.git"
  gh auth setup-git
else
  echo "ERROR: Set GITHUB_TOKEN or run: gh auth login"
  exit 1
fi

# Stay on export branch if that's what we have (do NOT merge limagica main)
CURRENT="$(git branch --show-current 2>/dev/null || echo "")"
if [[ "${CURRENT}" == "export/mywork-full-0966" ]] || [[ ! -f "${ROOT}/app/app.py" ]]; then
  echo "==> Using Priya project files from current branch: ${CURRENT}"
else
  git checkout export/mywork-full-0966 2>/dev/null || true
fi

git add -A
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "Priya news anchor: newsroom YouTube Shorts, update.sh, automation" || true
fi

# Push to mywork repo (separate remote — never overwrite limagica)
git remote remove mywork 2>/dev/null || true
git remote add mywork "${MYWORK_URL}"

echo "==> Pushing to niks12/mywork main..."
git push -u mywork HEAD:"${BRANCH}" --force

echo
echo "=============================================="
echo " SUCCESS — https://github.com/${MYWORK_REPO}"
echo "=============================================="
echo
echo "On laptop:"
echo "  cd ~ && rm -rf mywork"
echo "  git clone \"https://\${GITHUB_TOKEN}@github.com/${MYWORK_REPO}.git\" mywork"
echo "  cd mywork && bash update.sh"
