#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SCRIPT="$ROOT/.harness/scripts/call-codex.sh"
STUB="$ROOT/.harness/verifications/_shared/codex-stub"
[[ -x "$SCRIPT" ]] || fail "missing script"
scratch=$(mk_scratch ac-B.2-edge)
trap "cleanup_scratch $scratch" EXIT

for tok in "" "not-a-real-key"; do
  set +e
  PATH="$STUB:/usr/bin:/bin" OPENAI_API_KEY="$tok" "$SCRIPT" <<<"p" >"$scratch/out" 2>"$scratch/err"
  rc=$?
  set -e
  [[ $rc -eq 2 ]] || fail "stale-token(tok='$tok'): expected rc==2, got $rc"
  grep -qE '^⚠ Codex preflight failed: ' "$scratch/err" \
    || fail "stale-token(tok='$tok'): missing exact '⚠ Codex preflight failed: ' line-anchored prefix"
  [[ ! -s "$scratch/out" ]] || fail "stale-token: stdout non-empty on preflight abort (leak)"
done
pass "AC-B.2 edge (rc==2 exact, no stdout leak)"
