#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
R="$(repo_root)/.harness/experiments/baseline-variance/README.md"
[[ -f "$R" ]] || fail "missing README"
wc=$(wc -w <"$R" | tr -d ' ')
(( wc >= 40 )) || fail "README too short: $wc words (<40)"
# Must reference σ-based / variance-based threshold, per iter-4 boundary.
grep -qiE 'sigma|σ|variance|standard deviation|표준편차' "$R" \
  || fail "README must reference σ/variance-based evaluation"
# Must NOT fixate on an absolute recall-lift threshold (forbidden by boundary).
if grep -qE '15[[:space:]]*(pp|%)[[:space:]]*(recall|lift)' "$R"; then
  fail "README must not hardcode 15pp recall threshold (forbidden by iter-4 boundaries)"
fi
pass "AC-A.1 edge"

