#!/usr/bin/env bash
# Push full Priya News project to GitHub main (one command on your laptop).
#
# Usage:
#   export GITHUB_TOKEN="ghp_your_personal_access_token"
#   bash push-to-github.sh
#
# Or use GitHub CLI (already logged in):
#   gh auth login
#   bash push-to-github.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

REPO="niks12/mywork"
BRANCH="main"
FEATURE="cursor/female-multilingual-avatar-d1ec"

echo "==> Push Priya News to GitHub: ${REPO} (${BRANCH})"

# Clean large generated files
rm -rf shorts/.venv shorts/output shorts/.state 2>/dev/null || true

# Merge feature into main locally
git checkout "${BRANCH}" 2>/dev/null || git checkout -b "${BRANCH}"
if git show-ref --verify --quiet "refs/heads/${FEATURE}"; then
  git merge "${FEATURE}" -m "Merge ${FEATURE} into main" 2>/dev/null || true
fi

git add -A
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "Priya news anchor: newsroom YouTube Shorts, update.sh, full automation" || true
fi

# Auth: GITHUB_TOKEN or gh CLI
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH="https://${GITHUB_TOKEN}@github.com/${REPO}.git"
elif command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  AUTH="https://github.com/${REPO}.git"
  gh auth setup-git
else
  echo
  echo "ERROR: Need GitHub auth."
  echo
  echo "Option A — Personal Access Token:"
  echo "  https://github.com/settings/tokens → Generate (classic) → repo scope"
  echo "  export GITHUB_TOKEN='ghp_xxxx'"
  echo "  bash push-to-github.sh"
  echo
  echo "Option B — GitHub CLI:"
  echo "  gh auth login"
  echo "  bash push-to-github.sh"
  exit 1
fi

if git remote get-url origin 2>/dev/null | grep -q github.com; then
  git remote set-url origin "${AUTH}"
  REMOTE="origin"
else
  git remote remove github 2>/dev/null || true
  git remote add github "${AUTH}"
  REMOTE="github"
fi

echo "==> Pushing to GitHub main..."
git push -u "${REMOTE}" "${BRANCH}" --force

echo
echo "=============================================="
echo " DONE — live on GitHub main"
echo "=============================================="
echo "  https://github.com/${REPO}"
echo
echo "On any laptop:"
echo "  git clone https://github.com/${REPO}.git ~/mywork"
echo "  cd ~/mywork && bash update.sh"
