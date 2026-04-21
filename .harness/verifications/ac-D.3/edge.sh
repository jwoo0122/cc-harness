#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"

sec=$(md_section "$S" "## Phase 1")
printf '%s\n' "$sec" | grep -qiE 'markdown.bullet|bullet.list|plan format|increment.plan|inc entries' \
  || fail "Phase 1 lacks format-structure reference (expected 'bullet list', 'markdown bullet', 'plan format', or similar)"
printf '%s\n' "$sec" | grep -qiE 'parse|format|mismatch|fails to parse|well-formed' \
  || fail "Phase 1 lacks parse/format-failure fallback mention"
if printf '%s\n' "$sec" | grep -qiE 'silently accept|accept regardless|skip parse check'; then
  fail "Phase 1 contains forbidden 'silent acceptance' language"
fi
pass "AC-D.3 edge (SKILL.md format-constraint prose complete)"
