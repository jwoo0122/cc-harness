#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
HOOK="$(repo_root)/skills/explore/block-mutating.sh"
[[ -x "$HOOK" ]] || fail "block-mutating.sh missing or not executable"
# Whitelisted call → allowed
set +e
printf '%s' '{"tool_name":"Bash","agent_type":"skp","tool_input":{"command":"skills/_shared/call-codex.sh"}}' \
  | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 0 )) || fail "explore whitelist did not allow call-codex.sh (rc=$rc)"
# Non-whitelisted Bash → blocked
set +e
printf '%s' '{"tool_name":"Bash","agent_type":"skp","tool_input":{"command":"ls"}}' \
  | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 2 )) || fail "explore arbitrary Bash not blocked (rc=$rc)"
# Edit still blocked in explore
set +e
printf '%s' '{"tool_name":"Edit","agent_type":"skp","tool_input":{"file_path":"a"}}' \
  | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
(( rc == 2 )) || fail "explore Edit not blocked (rc=$rc)"
pass "AC-C.2 happy"
