#!/usr/bin/env bash
set -euo pipefail

# Required env:
# - GH_TOKEN (or GITHUB_TOKEN)
# - GITHUB_REPOSITORY (owner/repo is provided by Actions automatically)
# - PR_NUMBER (we’ll set this in the workflow)

# Sanity checks
: "${GH_TOKEN:?Missing GH_TOKEN}"
: "${GITHUB_REPOSITORY:?Missing GITHUB_REPOSITORY}"
: "${PR_NUMBER:?Missing PR_NUMBER}"

API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments"

# Simple friendly message. You can expand this later.
BODY="👋 Thanks for the PR! This is an automated greeting while we wire up checks."

# Post the comment
# (Ubuntu runners have jq; if you prefer no jq, I’ve left a curl-only version below.)
curl -sS -X POST \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "${API_URL}" \
  -d "$(jq -n --arg body "$BODY" '{body: $body}')"

# --- No-jq alternative ---
# payload=$(printf '{"body": "%s"}' "$(printf '%s' "$BODY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])')")
# curl -sS -X POST \
#   -H "Authorization: Bearer ${GH_TOKEN}" \
#   -H "Accept: application/vnd.github+json" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   -d "$payload" \
#   "${API_URL}"

echo "Posted comment to PR #${PR_NUMBER} in ${GITHUB_REPOSITORY}."
