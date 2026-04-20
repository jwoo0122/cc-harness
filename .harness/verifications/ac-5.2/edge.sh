#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"

echo "$P3" | grep -qiE 'report appendix|phase 3 report' \
  || fail "3c does not route choice + freetext into the Phase 3 report"
ok "report appendix mentioned"

echo "$P3" | grep -qiE 'log the chosen option' \
  || fail "3c does not state that the chosen option is logged"
ok "choice logging stated"

pass "ac-5.2 edge PASS"
