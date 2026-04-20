#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/explore/SKILL.md"
[[ -f "$SKILL" ]] || fail "skills/explore/SKILL.md missing"

grep -qF '^\.iteration-[1-9][0-9]*$' "$SKILL" \
  || fail "explore SKILL.md does not contain the required regex literal"

command -v python3 >/dev/null || fail "python3 required as regex oracle"

python3 - <<'PY'
import re, sys
pat = re.compile(r'^\.iteration-[1-9][0-9]*$')
good = ['.iteration-1', '.iteration-2', '.iteration-10', '.iteration-99', '.iteration-123']
bad  = [
    '.iteration-0', '.iteration-01', '.iteration-', '.iteration',
    'iteration-1', '.Iteration-1', '.iteration-1 ', ' .iteration-1',
    '.iteration-1a', '.iteration-1/', '.iteration--1', '.iteration-1.2',
]
fails = []
for g in good:
    if not pat.match(g): fails.append(f'expected MATCH for {g!r}')
for b in bad:
    if pat.match(b):     fails.append(f'expected REJECT for {b!r}')
if fails:
    print('REGEX-SPEC FAIL:', *fails, sep='\n  '); sys.exit(1)
print('regex spec consistent with criteria (5 good, 12 bad cases)')
PY

pass "ac-1.2-explore edge PASS"
