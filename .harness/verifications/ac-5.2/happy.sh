#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"
[[ -n "$P3" ]] || fail "Phase 3 not locatable"

echo "$P3" | grep -qE '\.iteration-<N\+1>/' \
  || fail "3c does not literally reference .iteration-<N+1>/ as the persistence target"
ok ".iteration-<N+1>/ literally referenced"

echo "$P3" | grep -q 'decision-log\.md' \
  || fail "3c does not name decision-log.md"
ok "decision-log.md named"

echo "$P3" | grep -qiE 'next[[:space:]]+/explore|inherit|re-?entering the loop' \
  || fail "3c does not state that /explore inherits the rationale"
ok "/explore inheritance stated"

pass "ac-5.2 happy PASS"
