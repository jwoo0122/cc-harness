#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"

echo "$P3" | grep -qiE 'do not accept.*(Y/N|empty)|reject.*(empty|Y/N)|not accept.*empty' \
  || fail "3c does not reject empty / Y-N freetext replies"
ok "empty / Y-N rejection present"

echo "$P3" | grep -qiE 'rubber[- ]?stamp' \
  || fail "3c lacks rubber-stamp rationale for freetext gate"
ok "rubber-stamp rationale stated"

pass "ac-5.1b edge PASS"
