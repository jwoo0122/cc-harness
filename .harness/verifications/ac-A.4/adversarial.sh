#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/.harness/experiments/baseline-variance/summary.md"
[[ -f "$S" ]] || fail "summary.md missing"
# One of the three caveat formulations must appear (case-insensitive).
# correlated.*failure  |  echo.chamber  |  rabbit.hole.*6
if ! grep -qiE 'correlated[[:space:]]+failure|echo[[:space:]-]*chamber|rabbit[[:space:]-]*hole.*6' "$S"; then
  fail "summary.md missing rabbit-hole #6 caveat (correlated-failure / echo-chamber / rabbit-hole 6)"
fi
# And the caveat must acknowledge that baseline variance alone does NOT
# protect against this — no dismissive phrasing.
if grep -qiE 'baseline[[:space:]]+variance[[:space:]]+(prevents|solves|protects[[:space:]]+against)[[:space:]]+(correlated|echo)' "$S"; then
  fail "summary.md falsely claims baseline variance prevents correlated failure"
fi
pass "AC-A.4 adversarial"

