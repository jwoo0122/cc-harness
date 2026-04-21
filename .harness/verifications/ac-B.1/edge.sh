#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/skills/_shared/call-codex.sh"
[[ -x "$SCRIPT" ]] || fail "call-codex.sh missing"
scratch=$(mk_scratch ac-B.1-edge)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=ok
export CODEX_STUB_STDIN_DUMP="$scratch/stdin"
# Feed empty stdin with a 10s timeout on the test itself.
set +e
: | timeout 10 "$SCRIPT" >"$scratch/out" 2>"$scratch/err"
rc=$?
set -e
(( rc != 124 )) || fail "call-codex.sh hung on empty stdin (timed out by test harness)"
# Empty stdin must be forwarded as empty (no injection of placeholder text).
if [[ -s "$scratch/stdin" ]]; then
  # Allow a trailing newline only.
  bytes=$(wc -c <"$scratch/stdin" | tr -d ' ')
  (( bytes <= 1 )) || fail "call-codex.sh fabricated content on empty stdin ($bytes bytes)"
fi
pass "AC-B.1 edge (rc=$rc)"

