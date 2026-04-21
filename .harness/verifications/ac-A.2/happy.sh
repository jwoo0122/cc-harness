#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
IN="$DIR/inputs"
[[ -d "$IN" ]] || fail "inputs/ missing"
count=$(find "$IN" -maxdepth 1 -type f | wc -l | tr -d ' ')
(( count >= 3 )) || fail "expected >=3 corpus files, got $count"
# Require each file non-empty.
while IFS= read -r f; do
  [[ -s "$f" ]] || fail "empty corpus file: $f"
done < <(find "$IN" -maxdepth 1 -type f)
pass "AC-A.2 happy ($count files)"

