#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"
[[ -n "$P3" ]] || fail "Phase 3 not locatable"

echo "$P3" | grep -q 'HARNESS_DISABLE_CHECKPOINT' \
  || fail "Phase 3 missing HARNESS_DISABLE_CHECKPOINT name"
ok "env var name present"

echo "$P3" | grep -qiE 'skip.*checkpoint|checkpoint.*skipped|exits after' \
  || fail "Phase 3 does not describe the skip branch"
ok "skip branch described"

pass "ac-5.3 happy PASS"
