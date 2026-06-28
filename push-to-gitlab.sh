#!/usr/bin/env bash
# Push mywork (Priya News) to GitLab and ensure main has everything.
#
# Usage:
#   export GITLAB_TOKEN="your-gitlab-personal-access-token"
#   export GITLAB_URL="https://gitlab.com"          # or your self-hosted URL
#   export GITLAB_PROJECT="niks12/mywork"           # group/project path
#   bash push-to-gitlab.sh
#
# Or on laptop after clone:
#   cd ~/mywork && bash push-to-gitlab.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
GITLAB_PROJECT="${GITLAB_PROJECT:-niks12/mywork}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
BRANCH_MAIN="main"
FEATURE_BRANCH="cursor/female-multilingual-avatar-d1ec"

if [[ -z "${GITLAB_TOKEN}" ]]; then
  echo "ERROR: Set GITLAB_TOKEN first."
  echo
  echo "  1. GitLab → Preferences → Access Tokens"
  echo "  2. Create token with scopes: api, read_repository, write_repository"
  echo "  3. Run:"
  echo "       export GITLAB_TOKEN='glpat-xxxxxxxx'"
  echo "       bash push-to-gitlab.sh"
  exit 1
fi

ENCODED_PROJECT=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${GITLAB_PROJECT}', safe=''))")

echo "==> GitLab: ${GITLAB_URL}/${GITLAB_PROJECT}"

# Create project if missing
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "${GITLAB_URL}/api/v4/projects/${ENCODED_PROJECT}")

if [[ "${HTTP_CODE}" == "404" ]]; then
  echo "==> Creating GitLab project ${GITLAB_PROJECT}..."
  curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    -X POST "${GITLAB_URL}/api/v4/projects" \
    --data "name=mywork" \
    --data "path=mywork" \
    --data "visibility=private" \
    --data "initialize_with_readme=false" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('web_url','created'))" 2>/dev/null || true
fi

# Ensure feature branch is merged into main locally
git checkout "${BRANCH_MAIN}" 2>/dev/null || git checkout -b "${BRANCH_MAIN}"
if git show-ref --verify --quiet "refs/heads/${FEATURE_BRANCH}"; then
  git merge "${FEATURE_BRANCH}" -m "Merge ${FEATURE_BRANCH} into main" || true
fi

# Remove large/generated files before push
rm -rf shorts/.venv shorts/output shorts/.state/config.env 2>/dev/null || true
git add -A
if ! git diff --cached --quiet; then
  git commit -m "Prepare clean export for GitLab" || true
fi

REMOTE_URL="${GITLAB_URL%/}/${GITLAB_PROJECT}.git"
AUTH_URL="${GITLAB_URL/https:\/\//https://oauth2:${GITLAB_TOKEN}@}/${GITLAB_PROJECT}.git"

if git remote get-url gitlab >/dev/null 2>&1; then
  git remote set-url gitlab "${AUTH_URL}"
else
  git remote add gitlab "${AUTH_URL}"
fi

echo "==> Pushing main to GitLab..."
git push -u gitlab "${BRANCH_MAIN}" --force

echo "==> Pushing feature branch (backup)..."
git push gitlab "${FEATURE_BRANCH}" 2>/dev/null || true

echo
echo "=============================================="
echo " DONE — pushed to GitLab main"
echo "=============================================="
echo "  ${GITLAB_URL}/${GITLAB_PROJECT}"
echo
echo "On laptop:"
echo "  git clone ${REMOTE_URL}"
echo "  cd mywork"
echo "  bash update.sh"
