#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
P="$(repo_root)/.harness/experiments/baseline-variance/codex-pln-probe.md"
[[ -f "$P" ]] || fail "codex-pln-probe.md missing"
grep -qE 'HARNESS_PLN_PROVIDER[[:space:]]*=?[[:space:]]*codex' "$P" \
  || fail "probe doc does not reference HARNESS_PLN_PROVIDER=codex"
# Must record at least one of: stance_agreement_rate, round3_survival_rate, σ, mean
grep -qiE 'stance_agreement|round3_survival|σ|sigma|mean|평균' "$P" \
  || fail "probe doc has no metric recordings"
pass "AC-E.2 happy"
