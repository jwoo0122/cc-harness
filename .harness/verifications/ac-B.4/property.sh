#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
scratch=$(mk_scratch ac-B.4-prop)
trap "cleanup_scratch $scratch" EXIT
cat >"$scratch/codex" <<'STUB'
#!/usr/bin/env bash
cat >"$CODEX_STDIN_DUMP"
printf '{"type":"message","content":"ok"}\n'
STUB
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
failures=0
for i in $(seq 1 30); do
  SEED="$i" python3 <<'PY' >"$scratch/prompt.$i"
import os, sys, random
seed = int(os.environ['SEED']) * 31337
random.seed(seed)
alphabet = list('abcdef0123 \n\t`$*?|><&;"\'\\()[]{}') + ['유', '中', '\u200d', '\u0000']
out = ''.join(random.choice(alphabet) for _ in range(random.randint(1, 256)))
sys.stdout.write(out)
PY
  export CODEX_STDIN_DUMP="$scratch/stdin.$i"
  if ! "$SCRIPT" <"$scratch/prompt.$i" >/dev/null 2>"$scratch/err.$i"; then
    echo "[case $i] script non-zero exit" >&2; failures=$((failures+1)); continue
  fi
  if ! diff -q "$scratch/prompt.$i" "$scratch/stdin.$i" >/dev/null; then
    echo "[case $i] stdin mutated" >&2; failures=$((failures+1))
  fi
done
(( failures == 0 )) || fail "$failures/30 random prompts were mishandled"
pass "AC-B.4 property (30/30)"
