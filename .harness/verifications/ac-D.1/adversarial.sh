#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
# Try both heading forms.
sec2d=$(md_section "$S" "### 2d. AC cross-check" || true)
if [[ -z "$sec2d" ]]; then sec2d=$(md_section "$S" "## Phase 2d" || true); fi
if [[ -z "$sec2d" ]]; then
  sec2d=$(awk '/^## Phase 2/{f=1} f{print} /^## Phase 3/{exit}' "$S")
fi
[[ -n "$sec2d" ]] || fail "Phase 2 (with 2d) section not found"
if printf '%s\n' "$sec2d" | grep -qE 'HARNESS_PLN_PROVIDER'; then
  fail "Phase 2d region mentions HARNESS_PLN_PROVIDER — scope creep, violates D.4 (Claude-only cross-check)"
fi
pass "AC-D.1 adversarial"
