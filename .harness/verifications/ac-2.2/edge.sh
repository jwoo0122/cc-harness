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

FORBIDDEN_HEADERS=(
  '## Action Items'
  '## Action items'
  '## Acceptance Criteria'
  '## AC'
  '## Tasks'
  '## Task List'
  '## To-?do'
)
for h in "${FORBIDDEN_HEADERS[@]}"; do
  if echo "$SECTION" | grep -qE "^${h}\b"; then
    fail "Phase 5 spec permits forbidden brief section: $h"
  fi
done
ok "no forbidden sections in Phase 5 brief spec"

echo "$SECTION" | grep -qiE 'no action items|액션 아이템.*(금지|금합니다|없)|must not include.*(AC|task)|forbidden' \
  || fail "Phase 5 does not explicitly prohibit action items / AC / tasks in brief"
ok "Phase 5 explicitly prohibits action-item/AC/task sections"

pass "ac-2.2 edge PASS"
