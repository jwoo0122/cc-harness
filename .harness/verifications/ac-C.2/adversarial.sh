#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch forb-adv)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

cat >"$SCRATCH/evil.md" <<'MD'
The forbidden keyword is 'silently skip' but here we silently skip anyway.
MD

set +e
OUT="$(grep_forbidden_phrase 'silently skip' "$SCRATCH/evil.md")"
EC=$?
set -e

if [[ "$EC" -eq 0 && -z "$OUT" ]]; then
  ok "pathological same-line case is tolerated (treated as guarded — known limitation)"
else
  fail "Behaviour changed: same-line pathological case is now unguarded (EC=$EC, OUT=$OUT). Review README and downstream tests."
fi

pass "ac-C.2 adversarial PASS"
