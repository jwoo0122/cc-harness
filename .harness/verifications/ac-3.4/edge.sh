#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P0="$(md_section "$SKILL" "## Phase 0")"

echo "$P0" | grep -qEi 'legacy|criteria[- ]?only|haven.?t migrated|pre[- ]brief' \
  || fail "Phase 0 does not justify the legacy / criteria-only fallback"
ok "legacy fallback justification present"

echo "$P0" | awk '
  /HARNESS_DISABLE_BRIEF/ { context = 1; window = 6 }
  context && window-- > 0 { print }
' | grep -qiE 'legacy|criteria|migrated|manual' \
  || fail "HARNESS_DISABLE_BRIEF escape hatch lacks nearby rationale"
ok "rationale adjacent to env var"

pass "ac-3.4 edge PASS"
