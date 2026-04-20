#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SCRATCH="$(mk_scratch harness-ac-2-4)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

python3 - "$SCRATCH/oversize.md" <<'PY'
import sys
path = sys.argv[1]
with open(path, 'w') as f:
    f.write('## Bet\n')
    f.write(' '.join(f'word{i}' for i in range(3000)) + '\n')
PY

python3 - "$SCRATCH/oversize.md" "$SCRATCH/truncated.md" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
LIMIT = 2000
with open(src) as f: text = f.read()
words = text.split()
if len(words) > LIMIT:
    truncated = ' '.join(words[:LIMIT])
    with open(dst, 'w') as f:
        f.write(truncated + '\n')
        f.write('<!-- truncated -->\n')
else:
    with open(dst, 'w') as f: f.write(text)
PY

BODY_WORDS=$(sed '/<!-- truncated -->/,$d' "$SCRATCH/truncated.md" | wc -w | tr -d ' ')
(( BODY_WORDS <= 2000 )) || fail "body before marker has $BODY_WORDS words (> 2000)"
ok "body within 2000-word cap ($BODY_WORDS)"

MARK_COUNT=$(grep -cF '<!-- truncated -->' "$SCRATCH/truncated.md")
[[ "$MARK_COUNT" == "1" ]] || fail "marker count = $MARK_COUNT (expected 1)"
ok "marker appears exactly once"

tail -n1 "$SCRATCH/truncated.md" | grep -qxF '<!-- truncated -->' \
  || fail "marker is not on a trailing line of its own"
ok "marker on final line"

pass "ac-2.4 edge PASS"
