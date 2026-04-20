#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch forb-edge)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

cat >"$SCRATCH/families.md" <<'MD'
must not silently skip this
do not silently skip that
We forbidden silently skip construct — phrased oddly but declarative
silently skip은 금지 사항이다
Never silently skip anomalies
shall not silently skip bulletins
don't silently skip anything
cannot silently skip critical paths
MD

set +e
OUT="$(grep_forbidden_phrase 'silently skip' "$SCRATCH/families.md")"
EC=$?
set -e

[[ "$EC" -eq 0 ]] || fail "expected all 8 lines to be guarded (EC=0), got EC=$EC; leaked lines: $OUT"
[[ -z "$OUT" ]] || fail "expected zero leaked lines; got: $OUT"
ok "all declaration families honoured"

cat >"$SCRATCH/bare.md" <<'MD'
we silently skip it and move on
MD
set +e
OUT2="$(grep_forbidden_phrase 'silently skip' "$SCRATCH/bare.md")"
EC2=$?
set -e
[[ "$EC2" -eq 1 ]] || fail "negative-control failed: EC=$EC2"
echo "$OUT2" | grep -q 'we silently skip' || fail "negative-control missing expected line"
ok "negative control passes"

pass "ac-C.2 edge PASS"
