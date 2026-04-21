#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
HOOK="$ROOT/skills/execute/gate-mutating.sh"
SHARED="$ROOT/skills/_shared/_provider-allowlist.sh"
[[ -f "$SHARED" ]] || fail "skills/_shared/_provider-allowlist.sh missing (C.1 integration self-amendment)"
# Hook must reference the shared file by path OR source it.
grep -qE '_provider-allowlist\.sh|source[[:space:]]+.*_provider-allowlist' "$HOOK" \
  || fail "gate-mutating.sh does not source the shared allowlist"
# Dynamic: temporarily point the hook at a modified shared file via env
# HARNESS_PROVIDER_ALLOWLIST (if supported) OR patch in place with a restore trap.
scratch=$(mk_scratch ac-C.1-adv)
trap "cleanup_scratch $scratch; cp '$scratch/backup' '$SHARED' 2>/dev/null || true" EXIT
cp "$SHARED" "$scratch/backup"
# Append a made-up provider 'unicorn'.
{
  echo ''
  echo '# test injection — AC-C.1 adversarial'
  echo 'HARNESS_PROVIDERS="${HARNESS_PROVIDERS:-} unicorn"'
} >>"$SHARED"
in='{"tool_name":"Bash","agent_type":"pln","tool_input":{"command":"skills/_shared/call-unicorn.sh"}}'
set +e
printf '%s' "$in" | "$HOOK" >/dev/null 2>/dev/null
rc=$?
set -e
cp "$scratch/backup" "$SHARED"
# If shared file is genuinely sourced, 'unicorn' was allowed (rc==0).
# If hook inlines a hardcoded list, 'unicorn' is rejected (rc!=0).
(( rc == 0 )) || fail "hook does not dynamically source shared allowlist (rc=$rc for 'unicorn')"
pass "AC-C.1 adversarial"
