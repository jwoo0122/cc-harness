#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
sec=$(md_section "$S" "## Phase 1")
printf '%s\n' "$sec" | grep -qiE 'parse.failure|parse-failure|fall.back.*parse|fails to parse|not well-formed|malformed' \
  || fail "Phase 1 lacks parse-failure fallback specificity (adversarial: Codex returns garbage)"
printf '%s\n' "$sec" | grep -qiE 'fall.back.*Claude|Claude.*fallback|claude subagent' \
  || fail "Phase 1 lacks Claude as explicit fallback target"
pass "AC-D.3 adversarial (SKILL.md parse-failure → Claude fallback)"
