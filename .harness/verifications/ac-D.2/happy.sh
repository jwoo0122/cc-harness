#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
sec=$(md_section "$S" "## Phase 1")
# Must mention both exit codes (or a range that covers them) AND fallback keyword.
if ! printf '%s\n' "$sec" | grep -qE 'exit[[:space:]]+(2|3|2/3|2 or 3|2,[[:space:]]*3)'; then
  fail "Phase 1 does not mention Codex exit 2/3 trigger"
fi
if ! printf '%s\n' "$sec" | grep -qiE 'fall[[:space:]-]?back|fallback|claude[[:space:]]+pln'; then
  fail "Phase 1 does not mention Claude PLN fallback"
fi
if ! printf '%s\n' "$sec" | grep -qiE 'loud|warn|stderr|경고'; then
  fail "Phase 1 does not mandate loud stderr warning on fallback"
fi
pass "AC-D.2 happy"
