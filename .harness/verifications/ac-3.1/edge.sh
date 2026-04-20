#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
SECTION="$(md_section "$SKILL" "## Phase 0")"
[[ -n "$SECTION" ]] || fail "Phase 0 section not locatable"

echo "$SECTION" | grep -qEi 'zero candidates|no candidates|If zero' \
  || fail "0a does not handle the zero-candidates branch"
ok "zero-candidates branch present"

echo "$SECTION" | grep -q '/explore' \
  || fail "0a zero-candidates branch does not mention /explore re-entry"
ok "/explore re-entry hint present"

if echo "$SECTION" | grep -qEi 'auto[- ]?create.*\.iteration-1|silently create'; then
  fail "0a appears to auto-create .iteration-1/ silently (forbidden)"
fi
ok "no silent auto-create of .iteration-1/"

pass "ac-3.1 edge PASS"
