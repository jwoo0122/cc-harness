#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"

echo "$P3" | awk '
  /HARNESS_DISABLE_CHECKPOINT/ { ctx = 1; window = 5 }
  ctx && window-- > 0 { print }
' | grep -qiE 'CI|automation|non-?interactive|impossible' \
  || fail "HARNESS_DISABLE_CHECKPOINT lacks CI/automation/non-interactive rationale nearby"

ok "rationale (CI/automation/non-interactive) present"
pass "ac-5.3 edge PASS"
