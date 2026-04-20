#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
[[ -f "$SKILL" ]] || fail "skills/execute/SKILL.md missing"

SECTION="$(md_section "$SKILL" "## Phase 0")"
[[ -n "$SECTION" ]] || fail "Phase 0 section not locatable"

echo "$SECTION" | grep -qE '^####[[:space:]]+0a\.' \
  || fail "Phase 0 missing the 0a subsection heading"
ok "0a heading present"

echo "$SECTION" | grep -qE '\.iteration-\*/?' \
  || fail "0a does not reference the .iteration-*/ glob"
ok ".iteration-*/ glob referenced"

echo "$SECTION" | grep -qE '\^\\\.iteration-\[1-9\]\[0-9\]\*\$' \
  || fail "0a does not state the canonical regex ^\\.iteration-[1-9][0-9]*\$"
ok "canonical regex stated"

echo "$SECTION" | grep -q 'AskUserQuestion' \
  || fail "0a multi-candidate branch does not name AskUserQuestion"
ok "AskUserQuestion referenced"

echo "$SECTION" | grep -qEi 'exactly one|single (valid )?candidate' \
  || fail "0a does not describe the single-candidate auto-pick branch"
ok "single-candidate branch covered"

echo "$SECTION" | grep -qEi 'abort.*hard error|hard[- ]error' \
  || fail "0a does not prescribe a hard-error abort on regex violation"
ok "hard-error abort prescribed"

pass "ac-3.1 happy PASS"
