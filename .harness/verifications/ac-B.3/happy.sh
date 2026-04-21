#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
scratch=$(mk_scratch ac-B.3-happy)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=ok
printf 'plan\n' | "$SCRIPT" >"$scratch/out" 2>"$scratch/err" || fail "fast call did not exit 0"
if grep -qiE 'timeout|timed out|⏱' "$scratch/err"; then
  fail "timeout warning emitted on fast call"
fi
pass "AC-B.3 happy"
