#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"

REGEX="$(awk '
  /^#### 0a\./ { inblk = 1 }
  inblk && /^```/ { fences++; if (fences == 1) next; if (fences == 2) exit }
  inblk && fences == 1 { print }
' "$SKILL" | head -n1)"

[[ -n "$REGEX" ]] || fail "Could not extract canonical regex from 0a"
ok "extracted regex: $REGEX"

python3 - "$REGEX" <<'PY' || fail "adversarial regex check failed"
import re, sys
pat = re.compile(sys.argv[1])
valid = [".iteration-1", ".iteration-2", ".iteration-10", ".iteration-999"]
invalid = [
    ".iteration-0", ".iteration-01", ".iteration-", ".iteration-1a",
    ".iteration-1 ", " .iteration-1", ".iteration-1/", ".iteration--1",
    ".Iteration-1", "iteration-1", ".iteration_1", ".iteration-1\n",
    ".iteration-1;rm -rf /",
]
for v in valid:
    assert pat.fullmatch(v), f"expected VALID: {v!r}"
for bad in invalid:
    assert not pat.fullmatch(bad), f"expected INVALID: {bad!r}"
print("regex oracle OK")
PY

pass "ac-3.1 adversarial PASS"
