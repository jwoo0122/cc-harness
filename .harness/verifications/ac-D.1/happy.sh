#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
[[ -f "$S" ]] || fail "SKILL.md missing"
sec=$(md_section "$S" "## Phase 1")
[[ -n "$sec" ]] || fail "Phase 1 section missing in SKILL.md"
if ! printf '%s\n' "$sec" | grep -qE 'HARNESS_PLN_PROVIDER[[:space:]]*=?[[:space:]]*codex'; then
  fail "Phase 1 section missing HARNESS_PLN_PROVIDER=codex branch"
fi
if ! printf '%s\n' "$sec" | grep -qE 'skills/_shared/call-codex\.sh'; then
  fail "Phase 1 section missing skills/_shared/call-codex.sh reference"
fi
if ! printf '%s\n' "$sec" | grep -qE 'subagent_type[[:space:]]*:[[:space:]]*"?pln"?'; then
  fail "Phase 1 section missing Claude PLN fallback (Agent subagent_type: pln)"
fi
pass "AC-D.1 happy"
