#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/.harness/experiments/baseline-variance/summary.md"
[[ -f "$S" ]] || fail "summary.md missing"
if grep -qiE 'nan|inf(inity)?' "$S"; then
  fail "summary.md contains NaN/Inf"
fi
# Look for at least one mean=<num> pattern and verify [0,1].
python3 - "$S" <<'PY' || fail "numeric sanity failed"
import re, sys
t=open(sys.argv[1]).read()
means=[float(x) for x in re.findall(r'(?i)mean[^0-9-]{0,10}(-?\d+\.?\d*)', t)]
sigmas=[float(x) for x in re.findall(r'(?:σ|sigma|std[^0-9-]{0,10})[^0-9-]{0,10}(-?\d+\.?\d*)', t, re.I)]
if not means: sys.exit("no mean numeric extracted")
for m in means:
  if not (0.0 <= m <= 1.0): sys.exit(f"mean out of [0,1]: {m}")
for s in sigmas:
  if s < 0: sys.exit(f"sigma negative: {s}")
PY
pass "AC-A.4 edge"

