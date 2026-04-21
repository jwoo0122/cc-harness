#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
[[ -f "$S" ]] || fail "SKILL.md missing"
sec=$(md_section "$S" "## Phase 1")
[[ -n "$sec" ]] || fail "Phase 1 section missing in SKILL.md"
# HARNESS_PLN_PROVIDER=codex must appear inside Phase 1.
if ! printf '%s\n' "$sec" | grep -qE 'HARNESS_PLN_PROVIDER[[:space:]]*=?[[:space:]]*codex'; then
  fail "Phase 1 section missing HARNESS_PLN_PROVIDER=codex branch"
fi
# call-codex.sh path must appear somewhere in Phase 1.
if ! printf '%s\n' "$sec" | grep -qE '\.harness/scripts/call-codex\.sh'; then
  fail "Phase 1 section missing .harness/scripts/call-codex.sh reference"
fi
# Fallback to existing Agent(subagent_type: "pln", ...) path must also be documented.
if ! printf '%s\n' "$sec" | grep -qE 'subagent_type[[:space:]]*:[[:space:]]*"?pln"?'; then
  fail "Phase 1 section missing Claude PLN fallback (Agent subagent_type: pln)"
fi
pass "AC-D.1 happy"
