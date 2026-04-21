#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/skills/_shared/call-codex.sh"
scratch=$(mk_scratch ac-B.4-happy)
trap "cleanup_scratch $scratch" EXIT
cat >"$scratch/codex" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$CODEX_ARGV_DUMP"
cat >"$CODEX_STDIN_DUMP"
printf '{"type":"message","content":"ok"}\n'
STUB
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_ARGV_DUMP="$scratch/argv"
export CODEX_STDIN_DUMP="$scratch/stdin"
PROMPT='THE QUICK BROWN FOX 1234567890'
printf '%s\n' "$PROMPT" | "$SCRIPT" >/dev/null 2>/dev/null
# Prompt must be in codex stdin.
grep -q "$PROMPT" "$scratch/stdin" || fail "prompt not forwarded via stdin"
# Prompt must NOT be smuggled into codex argv.
if grep -q "$PROMPT" "$scratch/argv"; then
  fail "prompt leaked into codex ARGV"
fi
pass "AC-B.4 happy"
