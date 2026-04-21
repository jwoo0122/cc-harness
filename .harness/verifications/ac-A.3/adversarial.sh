#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
SCRIPT=""
for n in run.sh measure.sh; do [[ -x "$DIR/$n" ]] && { SCRIPT="$DIR/$n"; break; }; done
[[ -n "$SCRIPT" ]] || fail "no run script"
scratch=$(mk_scratch ac-A.3-adv)
trap "cleanup_scratch $scratch" EXIT
# 1) Huge string.
python3 -c "import sys; sys.stdout.write('A'*500000)" >"$scratch/huge.txt"
# 2) Binary bytes.
printf '\x00\x01\x02\xffnot utf8 %s\n' "$(date)" >"$scratch/bin.txt"
RES="$DIR/results.jsonl"
pre=$(wc -l <"$RES" 2>/dev/null | tr -d ' ' || echo 0)
set +e
HARNESS_BASELINE_DRY=1 HARNESS_BASELINE_EXTRA_INPUT="$scratch/bin.txt" "$SCRIPT" >/dev/null 2>"$scratch/err"
rc=$?
set -e
# Either clean rejection (non-zero exit with a message) OR clean skip logged (zero exit)
# BUT results.jsonl must remain valid JSON either way.
post=$(wc -l <"$RES" 2>/dev/null | tr -d ' ' || echo 0)
python3 - "$RES" <<'PY' || fail "results.jsonl corrupted by adversarial input"
import json,sys
for i,l in enumerate(open(sys.argv[1]),1):
  l=l.strip()
  if not l: continue
  json.loads(l)
PY
if (( rc == 0 )) && (( post > pre )); then
  # script accepted; must have written a well-formed log entry with an error marker
  tail -1 "$RES" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); assert "error" in o or "skipped" in o, "silent accept of binary input"' \
    || fail "accepted binary input without marking error/skipped"
fi
pass "AC-A.3 adversarial (rc=$rc)"

