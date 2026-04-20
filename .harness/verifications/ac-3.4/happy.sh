#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P0="$(md_section "$SKILL" "## Phase 0")"
[[ -n "$P0" ]] || fail "Phase 0 not locatable"

echo "$P0" | grep -q 'HARNESS_DISABLE_BRIEF' \
  || fail "Phase 0 missing HARNESS_DISABLE_BRIEF env-var name"
ok "env var name present"

echo "$P0" | grep -qEi 'skip brief loading|brief loading skipped|skip.*brief' \
  || fail "Phase 0 does not describe skipping brief loading"
ok "skip branch documented"

echo "$P0" | grep -qEi 'log.*(skip|disabled)|skipped due to HARNESS_DISABLE_BRIEF' \
  || fail "Phase 0 does not specify a log line for the escape hatch"
ok "log line present"

pass "ac-3.4 happy PASS"
