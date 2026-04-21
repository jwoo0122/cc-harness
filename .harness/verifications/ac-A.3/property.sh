#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
RES="$(repo_root)/.harness/experiments/baseline-variance/results.jsonl"
[[ -f "$RES" ]] || fail "results.jsonl missing"
python3 - "$RES" <<'PY' || fail "schema property violated"
import json, math, sys
errs=[]
for i,l in enumerate(open(sys.argv[1]),1):
  l=l.strip()
  if not l: continue
  o=json.loads(l)
  sv=o.get("schema_version")
  if not (isinstance(sv,int) and sv>=1):
    errs.append(f"{i}: schema_version not int>=1: {sv!r}")
  for k in ("stance_agreement_rate","round3_survival_rate"):
    if k in o:
      v=o[k]
      if not isinstance(v,(int,float)) or math.isnan(v) or math.isinf(v):
        errs.append(f"{i}: {k} not finite number: {v!r}")
      elif not (0.0 <= float(v) <= 1.0):
        errs.append(f"{i}: {k} out of [0,1]: {v}")
if errs:
  for e in errs: print(e,file=sys.stderr)
  sys.exit(1)
PY
pass "AC-A.3 property"

