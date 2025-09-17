#!/usr/bin/env bash
set -euo pipefail

# Config: change here if your workflow filenames differ
BIRTH_WF="${BIRTH_WF:-check-birthdates.yml}"
COMMIT_WF="${COMMIT_WF:-commit-check.yml}"

# Ensure gh has a token (either GH_TOKEN or GITHUB_TOKEN)
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

# Required envs provided by Actions
EVENT_PATH="${GITHUB_EVENT_PATH:-}"
[ -f "$EVENT_PATH" ] || { echo "Missing GITHUB_EVENT_PATH"; exit 1; }

PR=$(jq -r '.workflow_run.pull_requests[0].number // empty' "$EVENT_PATH")
SHA=$(jq -r '.workflow_run.head_sha' "$EVENT_PATH")
REPO=$(jq -r '.workflow_run.repository.full_name' "$EVENT_PATH")

if [ -z "$PR" ]; then
  echo "No PR attached; exit."
  exit 0
fi

latest_json () {
  local wf="$1"
  gh api "repos/$REPO/actions/workflows/$wf/runs" \
    -f event=pull_request -f status=completed -f per_page=50 \
    -q ".workflow_runs[] | select(.head_sha==\"$SHA\") | {conclusion, html_url} | @json" \
  | head -n1
}

birth=$(latest_json "$BIRTH_WF" || true)
commit=$(latest_json "$COMMIT_WF" || true)

birth_conclusion=$(jq -r '.conclusion // empty' <<<"$birth")
birth_url=$(jq -r '.html_url // empty' <<<"$birth")
commit_conclusion=$(jq -r '.conclusion // empty' <<<"$commit")
commit_url=$(jq -r '.html_url // empty' <<<"$commit")

# Only proceed when BOTH runs completed for this SHA
if [ -z "$birth_conclusion" ] || [ -z "$commit_conclusion" ]; then
  echo "One or both workflows not finished yet (SHA $SHA). Exiting quietly."
  exit 0
fi

# Build the comment body using your dedicated renderer
chmod +x .github/scripts/build-pr-comment.sh
.github/scripts/build-pr-comment.sh \
  "$birth_conclusion" \
  "$commit_conclusion" \
  "$birth_url" \
  "$commit_url" > comment.md

# Post the comment to the PR (repo is the base repo; PR is from a fork)
gh pr comment "$PR" --repo "$REPO" --body-file comment.md
