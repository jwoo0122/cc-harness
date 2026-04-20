#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"
[[ -n "$P3" ]] || fail "Phase 3 not locatable"

for label in 'a' 'b' 'c'; do
  line="$(echo "$P3" | grep -E "\*\*\($label\)" | head -n1)"
  [[ -n "$line" ]] || fail "option ($label) line not found"
  wc_words=$(printf '%s\n' "$line" | wc -w | tr -d '[:space:]')
  if (( wc_words < 6 )); then
    fail "option ($label) description too short ($wc_words words): $line"
  fi
  ok "option ($label) has $wc_words words"
done

pass "ac-5.1a edge PASS"
