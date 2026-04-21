#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/.harness/experiments/baseline-variance/summary.md"
[[ -f "$S" ]] || fail "summary.md missing"
# Each of the four required stats must appear at least once.
grep -qiE 'mean|평균' "$S"               || fail "summary.md missing mean"
grep -qE 'σ|sigma|std[[:space:]]*dev'     "$S" || fail "summary.md missing σ/stddev"
grep -qE '95[[:space:]]*%|95%.*CI|confidence[[:space:]]+interval' "$S" \
  || fail "summary.md missing 95% CI"
grep -qiE 'n[[:space:]]*=[[:space:]]*[0-9]+|sample[[:space:]]*size|샘플[[:space:]]*수' "$S" \
  || fail "summary.md missing sample count"
pass "AC-A.4 happy"

