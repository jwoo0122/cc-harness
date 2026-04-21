#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

COUNT="$(awk '
  BEGIN { in_fence=0; run=0; tables=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; run=0; next }
  {
    if (!in_fence && $0 ~ /^\|.*\|[[:space:]]*$/) {
      run++
      if (run == 2) tables++
    } else {
      run = 0
    }
  }
  END { print tables }
' "$F")"

ok "table count = $COUNT (limit 1)"
if (( COUNT > 1 )); then
  fail "table count $COUNT exceeds 1"
fi
pass "ac-6.4 happy PASS (tables=$COUNT)"
