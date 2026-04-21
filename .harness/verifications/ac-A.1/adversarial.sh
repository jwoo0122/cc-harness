#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
R="$DIR/README.md"
[[ -d "$DIR/inputs" ]] || fail "inputs/ subdirectory missing"
# Every file inside inputs/ MUST appear by basename in README.
missing_in_readme=()
while IFS= read -r f; do
  bn="$(basename "$f")"
  grep -qF "$bn" "$R" || missing_in_readme+=("$bn")
done < <(find "$DIR/inputs" -maxdepth 1 -type f)
if (( ${#missing_in_readme[@]} > 0 )); then
  fail "README fails to enumerate corpus files: ${missing_in_readme[*]}"
fi
# Every basename mentioned in README under an inputs/ path must actually exist.
dangling=()
while IFS= read -r ref; do
  p="$DIR/$ref"
  [[ -f "$p" ]] || dangling+=("$ref")
done < <(grep -oE 'inputs/[A-Za-z0-9._-]+' "$R" | sort -u)
if (( ${#dangling[@]} > 0 )); then
  fail "README references nonexistent corpus entries: ${dangling[*]}"
fi
pass "AC-A.1 adversarial"

