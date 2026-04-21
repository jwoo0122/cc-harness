#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SCRIPT="$ROOT/.harness/scripts/call-codex.sh"
[[ -x "$SCRIPT" ]] || fail "missing executable: $SCRIPT"
scratch=$(mk_scratch ac-B.2-happy)
trap "cleanup_scratch $scratch" EXIT

set +e
PATH="/usr/bin:/bin" OPENAI_API_KEY="sk-test" "$SCRIPT" <<<"prompt" >"$scratch/out" 2>"$scratch/err"
rc=$?
set -e
[[ $rc -eq 2 ]] || fail "missing-binary: expected rc==2, got $rc"
grep -qE '⚠ Codex preflight failed: ' "$scratch/err" \
  || fail "missing-binary: stderr lacks '⚠ Codex preflight failed: <reason>' prefix"

STUB="$ROOT/.harness/verifications/_shared/codex-stub"
set +e
PATH="$STUB:/usr/bin:/bin" CODEX_STUB_MODE=ok "$SCRIPT" <<<"prompt" >"$scratch/out2" 2>"$scratch/err2"
rc=$?
set -e
[[ $rc -eq 2 ]] || fail "absent-token: expected rc==2, got $rc"
grep -qE '⚠ Codex preflight failed: ' "$scratch/err2" \
  || fail "absent-token: stderr lacks required warning prefix"
pass "AC-B.2 happy (rc==2 for missing-binary & absent-token)"
