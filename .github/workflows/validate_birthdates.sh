#!/usr/bin/env bash

# Checks a single edited file in data/birth-dates/*.txt against an answer key.
# Rules:
#   - Exactly ONE *.txt file in data/birth-dates/ must be edited in the PR (strict).
#   - Comparison ignores CRLF and outer whitespace/newlines.
#   - Fails on mismatch or rule violation; writes a short summary.

set -euo pipefail

BASE="${BASE_SHA:-}"
HEAD="${HEAD_SHA:-}"
if [[ -z "$BASE" || -z "$HEAD" ]]; then
  echo "BASE_SHA and HEAD_SHA must be set." >&2
  exit 2
fi

# Find changed target files in this PR
mapfile -t files < <(git diff --name-only "$BASE..$HEAD" -- 'data/birth-dates/*.txt' | tr -d '\r')

# Enforce exactly one changed file
count=${#files[@]}
{
  echo "### Birth-date checks"
  echo
} >> "$GITHUB_STEP_SUMMARY"

if [[ $count -ne 1 ]]; then
  echo "::error::Expected exactly 1 edited file in data/birth-dates/, found $count"
  if [[ $count -gt 0 ]]; then
    echo "| Files edited |" >> "$GITHUB_STEP_SUMMARY"
    echo "|---|" >> "$GITHUB_STEP_SUMMARY"
    for f in "${files[@]}"; do
      echo "| \`$(basename "$f")\` |" >> "$GITHUB_STEP_SUMMARY"
    done
  else
    echo "_No target files were changed._" >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 1
fi

file="${files[0]}"
basefile="$(basename "$file")"

# Lookup expected line from the answer key: format is "filename|exact expected line"
expected="$(
  grep -v '^[[:space:]]*#' .github/workflows/birthdates.tsv \
  | grep -m1 "^${basefile}|" \
  | cut -d'|' -f2-
)"

if [[ -z "$expected" ]]; then
  echo "::error file=${file}::No answer key entry for ${basefile}"
  echo "**${basefile}** – ❌ no answer key entry" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

# Read student's file: strip CRs, trim leading/trailing whitespace/newlines
got="$(
  tr -d '\r' < "$file" \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
)"

if [[ "$got" == "$expected" ]]; then
  echo "**${basefile}** – ✅ correct" >> "$GITHUB_STEP_SUMMARY"
else
  echo "::error file=${file}::Content does not match expected line"
  echo "**${basefile}** – ❌ mismatch" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "**Expected:**" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "\`$expected\`" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "**Got:**" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "\`$got\`" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi
