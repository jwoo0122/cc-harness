#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"

BUF="$(md_section "$SKILL" "## Phase 0")$'\n'$(md_section "$SKILL" "## Phase 1")"
[[ -n "$BUF" ]] || fail "Phase 0 / Phase 1 not locatable"

echo "$BUF" | awk '
  BEGIN { hit = 0 }
  /[Pp][Ll][Nn]/ && /[Rr]abbit[- ]hole/ { hit = 1 }
  END { exit (hit ? 0 : 1) }
' || fail "No single line couples PLN with rabbit-hole (constraint not clearly propagated)"
ok "PLN × rabbit-hole coupling present"

echo "$BUF" | grep -iE 'rabbit[- ]hole.*(constraint|must|explicit)' -q \
  || echo "$BUF" | grep -iE '(constraint|must|explicit).*rabbit[- ]hole' -q \
  || fail "rabbit-hole is mentioned but not framed as a PLN constraint"
ok "rabbit-hole framed as constraint"

pass "ac-3.2 edge PASS"
