#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SCRIPT="$ROOT/skills/_shared/call-codex.sh"
[[ -x "$SCRIPT" ]] || fail "call-codex.sh missing or not executable"
# argv sniffing stub: records argv+stdin, returns fixed JSONL
scratch=$(mk_scratch ac-B.1)
trap "cleanup_scratch $scratch" EXIT
cat >"$scratch/codex" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$CODEX_ARGV_DUMP"
cat >"$CODEX_STDIN_DUMP"
printf '{"type":"message","role":"assistant","content":"hello"}\n'
STUB
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export CODEX_ARGV_DUMP="$scratch/argv"
export CODEX_STDIN_DUMP="$scratch/stdin"
# Fake valid auth so preflight passes (AC-B.2 handles absence).
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
out=$(printf 'hello world\n' | "$SCRIPT")
# Stdout must be exactly the JSON Lines body.
printf '%s\n' "$out" | python3 -c 'import json,sys
for l in sys.stdin.read().splitlines():
  if l.strip(): json.loads(l)' || fail "stdout is not valid JSON Lines"
# argv must contain "exec" and "--json"
grep -qx 'exec' "$scratch/argv" || fail "codex not invoked with 'exec'"
grep -qx -- '--json' "$scratch/argv" || fail "codex not invoked with '--json'"
# stdin must have been forwarded verbatim
diff <(printf 'hello world\n') "$scratch/stdin" \
  || fail "stdin not forwarded to codex verbatim"
pass "AC-B.1 happy"

