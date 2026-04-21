#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
scratch=$(mk_scratch ac-B.4-edge)
trap "cleanup_scratch $scratch" EXIT
cat >"$scratch/codex" <<'STUB'
#!/usr/bin/env bash
cat >"$CODEX_STDIN_DUMP"
printf '{"type":"message","content":"ok"}\n'
STUB
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STDIN_DUMP="$scratch/stdin"
python3 - >"$scratch/prompt" <<'PY'
import sys
s = (
  "line1 `echo OWNED` $(echo pwned) * ? | > < & ; \n"
  "line2 유니코드 中文 "
  "\u200d"
  "\nline3 sk-REAL-but-test-0000000000000000000000000000\n"
)
sys.stdout.write(s)
PY
before_ls=$(cd "$scratch" && ls -A | sort | tr '\n' ' ')
"$SCRIPT" <"$scratch/prompt" >"$scratch/out" 2>"$scratch/err" || fail "script failed on metachar prompt"
after_ls=$(cd "$scratch" && ls -A | grep -vxE 'out|err|stdin' | sort | tr '\n' ' ')
[[ "$before_ls" == "$after_ls" ]] || fail "shell metachars created side-effect files in scratch: before=[$before_ls] after=[$after_ls]"
diff -q "$scratch/prompt" "$scratch/stdin" || fail "stdin byte-mutated during forwarding"
pass "AC-B.4 edge"
