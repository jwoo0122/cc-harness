#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
DIR="$(repo_root)/.harness/experiments/baseline-variance"
RES="$DIR/results.jsonl"
SCRIPT=""
for n in run.sh measure.sh; do [[ -x "$DIR/$n" ]] && { SCRIPT="$DIR/$n"; break; }; done
[[ -n "$SCRIPT" ]] || fail "no run script"
[[ -f "$RES" ]] || fail "results.jsonl missing"
before=$(wc -l <"$RES" | tr -d ' ')
snapshot=$(mk_scratch ac-A.3)
trap "cleanup_scratch $snapshot" EXIT
cp "$RES" "$snapshot/before.jsonl"
# Run with a harness-self-test env so it doesn't hit real /explore. Measurement
# script MUST honor HARNESS_BASELINE_DRY=1 to append a deterministic dry record.
HARNESS_BASELINE_DRY=1 "$SCRIPT" >/dev/null 2>&1 || fail "script exited non-zero under dry mode"
after=$(wc -l <"$RES" | tr -d ' ')
(( after > before )) || fail "append-only violated: before=$before after=$after"
# First $before lines must be byte-identical to snapshot.
head -n "$before" "$RES" | diff -q - "$snapshot/before.jsonl" \
  || fail "append-only violated: existing lines mutated"
pass "AC-A.3 edge (before=$before after=$after)"

