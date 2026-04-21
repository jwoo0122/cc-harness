#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SCRIPT="$ROOT/skills/_shared/call-codex.sh"
STUB="$ROOT/.harness/verifications/_shared/codex-stub"
scratch=$(mk_scratch ac-B.2-adv)
trap "cleanup_scratch $scratch" EXIT

set +e
PATH="/nonexistent:/tmp" OPENAI_API_KEY="sk-x" "$SCRIPT" <<<"p" >/dev/null 2>"$scratch/e1"
rc=$?
set -e
[[ $rc -eq 2 ]] || fail "preflight missing-binary under hostile PATH: expected rc==2, got $rc"
grep -qE '^⚠ Codex preflight failed: ' "$scratch/e1" \
  || fail "preflight missing-binary: warning prefix absent"

set +e
PATH="$STUB:/usr/bin:/bin" OPENAI_API_KEY="sk-x" CODEX_STUB_MODE=quota "$SCRIPT" <<<"p" >/dev/null 2>"$scratch/e2"
rc=$?
set -e
[[ $rc -ne 0 ]] || fail "quota: expected non-zero rc"
[[ $rc -ne 2 ]] || fail "quota: rc==2 would conflate with preflight category"
[[ -s "$scratch/e2" ]] || fail "quota: stderr empty (no diagnostic)"

set +e
PATH="$STUB:/usr/bin:/bin" OPENAI_API_KEY="sk-x" CODEX_STUB_MODE=network "$SCRIPT" <<<"p" >/dev/null 2>"$scratch/e3"
rc=$?
set -e
[[ $rc -ne 0 ]] || fail "network: expected non-zero rc"
[[ $rc -ne 2 ]] || fail "network: rc==2 would conflate with preflight category"
[[ -s "$scratch/e3" ]] || fail "network: stderr empty"
pass "AC-B.2 adversarial (preflight rc==2 strict; runtime rc!=0,!=2)"
