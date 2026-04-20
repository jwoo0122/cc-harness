#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/explore/SKILL.md"
[[ -f "$SKILL" ]] || fail "skills/explore/SKILL.md missing"

SECTION="$(md_section "$SKILL" "## Phase 5" || true)"
if [[ -z "$SECTION" ]]; then
  SECTION="$(awk '/^## .*Phase 5/,/^## /{ if(/^## /&&NR>1&&!/Phase 5/)exit; print }' "$SKILL")"
fi
[[ -n "$SECTION" ]] || fail "Phase 5 section not locatable"

echo "$SECTION" | grep -qE '\.iteration-N?/brief\.md|\.iteration-[0-9]+/brief\.md' \
  || fail "Phase 5 does not name .iteration-N/brief.md as the target"
ok ".iteration-N/brief.md referenced"

if echo "$SECTION" | grep -qE 'target/explore/'; then
  fail "Phase 5 still references legacy target/explore/ path"
fi
ok "no legacy target/explore path in Phase 5"

pass "ac-2.1 happy PASS"
