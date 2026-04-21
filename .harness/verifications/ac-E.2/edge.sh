#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
RES="$(repo_root)/.harness/experiments/baseline-variance/results.jsonl"
[[ -f "$RES" ]] || fail "results.jsonl missing"
python3 - "$RES" <<'PY' || fail "no provider=codex record found in results.jsonl"
import json, sys
found=False
for l in open(sys.argv[1]):
  l=l.strip()
  if not l: continue
  o=json.loads(l)
  if o.get("provider")=="codex" or o.get("pln_provider")=="codex":
    if "schema_version" in o:
      found=True; break
sys.exit(0 if found else 1)
PY
pass "AC-E.2 edge"
