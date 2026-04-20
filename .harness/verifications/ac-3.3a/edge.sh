#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P0="$(md_section "$SKILL" "## Phase 0")"

echo "$P0" | grep -q 'PLN' || fail "Phase 0 does not name PLN in the wrapping scope"
echo "$P0" | grep -q 'IMP' || fail "Phase 0 does not name IMP in the wrapping scope"
echo "$P0" | grep -q 'VER' || fail "Phase 0 does not name VER in the wrapping scope"
ok "all three roles covered by wrapping scope"

echo "$P0" | grep -qiE 'all[[:space:]]+(PLN|IMP|VER|dispatches|phase 1|subsequent)' \
  || echo "$P0" | grep -qiE 'every[[:space:]]+dispatch' \
  || fail "wrapping scope not stated as applying to all dispatches"
ok "scope universal across dispatches"

pass "ac-3.3a edge PASS"
