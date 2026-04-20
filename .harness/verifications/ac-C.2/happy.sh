#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch forb)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

cat >"$SCRATCH/mixed.md" <<'MD'
The system must not silently skip failures.
We silently skip this unusual input.
Do not silently skip errors.
MD

set +e
OUT="$(grep_forbidden_phrase 'silently skip' "$SCRATCH/mixed.md")"
EC=$?
set -e

[[ "$EC" -eq 1 ]] || fail "expected EC=1 when unguarded match exists, got $EC"
ok "EC=1 on unguarded match"

echo "$OUT" | grep -q 'We silently skip' || fail "bare unguarded line not reported"
ok "bare unguarded line reported"

if echo "$OUT" | grep -qi 'must not\|do not'; then
  fail "declaration-context line leaked into output"
fi
ok "declaration-context lines suppressed"

cat >"$SCRATCH/guarded.md" <<'MD'
The system must not silently skip failures.
Do not silently skip errors.
Never silently skip warnings.
MD

set +e
OUT2="$(grep_forbidden_phrase 'silently skip' "$SCRATCH/guarded.md")"
EC2=$?
set -e

[[ "$EC2" -eq 0 ]] || fail "expected EC=0 when all matches guarded, got $EC2"
[[ -z "$OUT2" ]] || fail "expected no output when all matches guarded, got: $OUT2"
ok "all-guarded → EC=0, empty output"

pass "ac-C.2 happy PASS"
