#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
R="$DIR/README.md"
hits=0
for src in 'iteration-1' 'iteration-2' 'meta-debate\|메타-?디베이트\|meta.debate'; do
  if grep -qiE "$src" "$R"; then hits=$((hits+1)); fi
done
(( hits >= 2 )) || fail "README must cite at least 2 of: iteration-1 / iteration-2 / meta-debate (got $hits)"
while IFS= read -r f; do
  head -5 "$f" | grep -qiE 'source|provenance|from|origin|iteration|meta|디베이트' \
    || fail "corpus file lacks provenance header (first 5 lines): $f"
done < <(find "$DIR/inputs" -maxdepth 1 -type f -name '*.md')
pass "AC-A.2 edge"
