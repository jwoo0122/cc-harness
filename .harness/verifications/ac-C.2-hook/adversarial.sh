#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
HOOK="$ROOT/skills/explore/block-mutating.sh"
SHARED="$ROOT/skills/_shared/_provider-allowlist.sh"
[[ -f "$SHARED" ]] || fail "shared provider allowlist missing"
grep -qE '_provider-allowlist\.sh|source[[:space:]]+.*_provider-allowlist' "$HOOK" \
  || fail "block-mutating.sh does not source the shared allowlist"
in='{"tool_name":"Bash","agent_type":"pln","tool_input":{"command":".harness/scripts/call-codex.sh"}}'
set +e; printf '%s' "$in" | "$HOOK" >/dev/null 2>/dev/null; rc=$?; set -e
(( rc == 0 )) || fail "baseline: call-codex.sh should be allowed"
scratch=$(mk_scratch ac-C.2-adv)
trap "cp '$scratch/backup' '$SHARED' 2>/dev/null; cleanup_scratch $scratch" EXIT
cp "$SHARED" "$scratch/backup"
awk '
  {
    if ($0 ~ /(^|[^A-Za-z0-9_])codex([^A-Za-z0-9_]|$)/) {
      print "# disabled by AC-C.2-adv: " $0
    } else {
      print $0
    }
  }
' "$scratch/backup" > "$scratch/modified"
if cmp -s "$scratch/backup" "$scratch/modified"; then
  fail "awk-based disable produced no change — token 'codex' not found in $SHARED"
fi
cp "$scratch/modified" "$SHARED"
set +e; printf '%s' "$in" | "$HOOK" >/dev/null 2>/dev/null; rc=$?; set -e
cp "$scratch/backup" "$SHARED"
(( rc == 2 )) || fail "removing 'codex' from shared allowlist did not block call-codex.sh (rc=$rc) — hook not dynamic"
pass "AC-C.2 adversarial"
