#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
HOOK="$(repo_root)/skills/execute/gate-mutating.sh"
# PLN arbitrary bash blocked
set +e
printf '%s' '{"tool_name":"Bash","agent_type":"pln","tool_input":{"command":"ls"}}' \
  | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 2 )) || fail "PLN 'ls' should block with exit 2, got $rc"
# Unknown agent type
set +e
printf '%s' '{"tool_name":"Bash","agent_type":"random","tool_input":{"command":"ls"}}' \
  | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 2 )) || fail "unknown agent 'ls' should block, got $rc"
# No agent_type field (orchestrator) with arbitrary bash
set +e
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 2 )) || fail "orchestrator Bash should block, got $rc"
pass "AC-C.1 edge"
