#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"
[[ -n "$P3" ]] || fail "Phase 3 not locatable"

echo "$P3" | grep -qiE 'at least one sentence|one[- ]sentence|at least a sentence' \
  || fail "3c does not require at least one sentence of freetext for option (a)"
ok "freetext requirement present"

echo "$P3" | grep -qE '\.iteration-<N\+1>/decision-log\.md|\.iteration-[0-9]+/decision-log\.md' \
  || fail "3c does not name .iteration-<N+1>/decision-log.md as the append target"
ok "decision-log append target present"

echo "$P3" | grep -qiE 'append' \
  || fail "3c does not use append semantics"
ok "append semantics stated"

pass "ac-5.1b happy PASS"
