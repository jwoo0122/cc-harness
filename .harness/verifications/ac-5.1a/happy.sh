#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
P3="$(md_section "$SKILL" "## Phase 3")"
[[ -n "$P3" ]] || fail "Phase 3 not locatable"

echo "$P3" | grep -qE '^### 3c\.' \
  || fail "Phase 3 missing 3c subsection heading"
ok "3c heading present"

echo "$P3" | grep -q 'AskUserQuestion' \
  || fail "3c does not call AskUserQuestion"
ok "AskUserQuestion present"

for label in '(a)' '(b)' '(c)'; do
  echo "$P3" | grep -qF "**$label" \
    || echo "$P3" | grep -qF "$label " \
    || fail "3c missing option $label"
done
ok "options (a)(b)(c) present"

if echo "$P3" | grep -qE '\*\*\(d\)|^\(d\)|\(d\) '; then
  fail "3c declares more than three options — (d) found"
fi
ok "exactly three options"

echo "$P3" | grep -q 'HARNESS_DISABLE_CHECKPOINT' \
  || fail "3c does not name HARNESS_DISABLE_CHECKPOINT"
ok "HARNESS_DISABLE_CHECKPOINT present"

pass "ac-5.1a happy PASS"
