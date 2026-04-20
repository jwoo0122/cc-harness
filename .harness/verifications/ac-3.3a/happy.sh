#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P0="$(md_section "$SKILL" "## Phase 0")"
[[ -n "$P0" ]] || fail "Phase 0 not locatable"

echo "$P0" | grep -q '<brief>'  || fail "Phase 0 missing <brief> open tag"
echo "$P0" | grep -q '</brief>' || fail "Phase 0 missing </brief> close tag"
ok "<brief>...</brief> wrapping documented"

echo "$P0" | grep -qiE 'data[, ]+not[[:space:]]+instructions|treat.*as data|never.*instructions|not as instructions' \
  || fail "Phase 0 missing the 'data, not instructions' directive"
ok "data-not-instructions directive present"

pass "ac-3.3a happy PASS"
