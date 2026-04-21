#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
scratch=$(mk_scratch ac-B.1-adv)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=ok
printf 'plan my increment\n' | "$SCRIPT" >"$scratch/out" 2>"$scratch/err"
# Every non-empty stdout line must parse as JSON.
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  printf '%s' "$line" | python3 -c 'import json,sys; json.loads(sys.stdin.read())' \
    || fail "non-JSON line leaked to stdout: $line"
done <"$scratch/out"
# Diagnostic markers (our own conventions) must not appear on stdout.
if grep -qE '⚠|WARN|preflight|DEBUG' "$scratch/out"; then
  fail "diagnostics leaked to stdout"
fi
pass "AC-B.1 adversarial"

