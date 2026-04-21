#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
DIR="$ROOT/.harness/experiments/baseline-variance"
[[ -d "$DIR" ]] || fail "missing dir: $DIR"
R="$DIR/README.md"
[[ -f "$R" ]] || fail "missing README: $R"
# Required substantive sections (case-insensitive). We require all four.
for re in 'purpose|목적' 'reproduc|재현' 'metric|메트릭|stance|agreement' 'source|corpus|코퍼스|archived'; do
  grep -qiE "$re" "$R" || fail "README missing section matching /$re/"
done
# Guard against placeholder/TODO.
if grep -qiE 'TODO|FIXME|lorem ipsum' "$R"; then
  fail "README still contains placeholder text"
fi
pass "AC-A.1 happy"

