#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
HOOK="$(repo_root)/skills/execute/gate-mutating.sh"
[[ -x "$HOOK" ]] || fail "gate-mutating.sh missing or not executable"
# Case 1: pln calling call-codex.sh → allowed (exit 0)
in1='{"tool_name":"Bash","agent_type":"pln","tool_input":{"command":"skills/_shared/call-codex.sh"}}'
printf '%s' "$in1" | "$HOOK" && rc1=0 || rc1=$?
(( rc1 == 0 )) || fail "PLN Bash call-codex.sh blocked (rc=$rc1)"
# Case 2: ver calling call-gemini.sh → allowed
in2='{"tool_name":"Bash","agent_type":"ver","tool_input":{"command":"skills/_shared/call-gemini.sh"}}'
printf '%s' "$in2" | "$HOOK" && rc2=0 || rc2=$?
(( rc2 == 0 )) || fail "VER Bash call-gemini.sh blocked (rc=$rc2)"
# Case 3: imp Edit → still allowed (existing policy)
in3='{"tool_name":"Edit","agent_type":"imp","tool_input":{"file_path":"a.md"}}'
printf '%s' "$in3" | "$HOOK" && rc3=0 || rc3=$?
(( rc3 == 0 )) || fail "IMP Edit regression (rc=$rc3)"
# Case 4: imp arbitrary Bash → still allowed
in4='{"tool_name":"Bash","agent_type":"imp","tool_input":{"command":"npm test"}}'
printf '%s' "$in4" | "$HOOK" && rc4=0 || rc4=$?
(( rc4 == 0 )) || fail "IMP arbitrary Bash regression (rc=$rc4)"
pass "AC-C.1 happy"
