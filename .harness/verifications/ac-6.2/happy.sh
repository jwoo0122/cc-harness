#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

PATTERNS=(
  '\bpowerful\b'
  '\bseamless\b'
  '\brevolutionary\b'
  '\bmagical\b'
  '\beffortless\b'
  '\bblazing\b'
  '\bcutting-edge\b'
  '\bgame-chang'
  '\bsimply\b'
  '\bjust works\b'
  '\brobust\b'
  '\belegant\b'
  '\bbeautiful\b'
)

TOTAL=0
for p in "${PATTERNS[@]}"; do
  n="$(grep -oiE "$p" "$F" | wc -l | tr -d '[:space:]' || true)"
  if (( n > 0 )); then
    ok "hype hit: $p x$n"
  fi
  TOTAL=$((TOTAL + n))
done
ok "total hype hits = $TOTAL (limit 4)"

if (( TOTAL > 4 )); then
  fail "hype-lexicon total $TOTAL exceeds 4"
fi
pass "ac-6.2 happy PASS (hits=$TOTAL)"
