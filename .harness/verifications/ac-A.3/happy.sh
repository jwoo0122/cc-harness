#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
# Accept either run.sh or measure.sh.
SCRIPT=""
for n in run.sh measure.sh; do
  [[ -x "$DIR/$n" ]] && { SCRIPT="$DIR/$n"; break; }
done
[[ -n "$SCRIPT" ]] || fail "no executable run.sh or measure.sh in $DIR"
RES="$DIR/results.jsonl"
[[ -f "$RES" ]] || fail "results.jsonl missing"
[[ -s "$RES" ]] || fail "results.jsonl empty — need at least one run recorded"
# Every line must be valid JSON with required fields.
python3 - "$RES" <<'PY' || fail "results.jsonl schema check failed"
import json, sys
required = {"schema_version","stance_agreement_rate","round3_survival_rate"}
bad = []
with open(sys.argv[1]) as fh:
    for i, line in enumerate(fh, 1):
        line=line.strip()
        if not line: continue
        try:
            o=json.loads(line)
        except Exception as e:
            bad.append((i,f"invalid json: {e}")); continue
        missing = required - o.keys()
        if missing: bad.append((i, f"missing fields: {missing}"))
if bad:
    for i,m in bad: print(f"line {i}: {m}", file=sys.stderr)
    sys.exit(1)
PY
pass "AC-A.3 happy"

