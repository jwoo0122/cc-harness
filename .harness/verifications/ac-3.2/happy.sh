#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
PLN="$ROOT/agents/pln.md"
[[ -f "$SKILL" ]] || fail "skills/execute/SKILL.md missing"
[[ -f "$PLN"   ]] || fail "agents/pln.md missing"

P0="$(md_section "$SKILL" "## Phase 0")"
[[ -n "$P0" ]] || fail "Phase 0 not locatable"

echo "$P0" | grep -qE 'brief\.md' \
  || fail "Phase 0 does not reference brief.md"
ok "brief.md referenced in Phase 0"

echo "$P0" | grep -qi 'rabbit[- ]hole' \
  || fail "Phase 0 does not mention rabbit-holes"
ok "rabbit-holes mentioned in Phase 0"

grep -qi '^## .*Rabbit[- ]hole' "$PLN" \
  || fail "agents/pln.md missing a Rabbit-hole section"
ok "pln.md rabbit-hole section present"

awk '/^## .*[Rr]abbit[- ]hole/,/^## /' "$PLN" \
  | grep -qiE 'constraint|flag|must|adversari' \
  || fail "pln.md rabbit-hole section lacks constraint/flag/adversarial language"
ok "pln.md rabbit-hole section imposes a constraint"

pass "ac-3.2 happy PASS"
