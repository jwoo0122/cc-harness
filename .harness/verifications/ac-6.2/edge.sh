#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch ac-6.2-edge)"
trap 'rm -rf "$SCRATCH"' EXIT

cat > "$SCRATCH/fake-README.md" <<'EOF'
# Title
This is a Powerful tool. It is POWERFUL and powerful.
It's also SEAMLESS and revolutionary.
But the word "powerfully" is an adverb and should NOT count.
EOF

PATTERNS=(
  '\bpowerful\b' '\bseamless\b' '\brevolutionary\b' '\bmagical\b'
  '\beffortless\b' '\bblazing\b' '\bcutting-edge\b' '\bgame-chang'
  '\bsimply\b' '\bjust works\b' '\brobust\b' '\belegant\b' '\bbeautiful\b'
)

TOTAL=0
for p in "${PATTERNS[@]}"; do
  n="$(grep -oiE "$p" "$SCRATCH/fake-README.md" | wc -l | tr -d '[:space:]' || true)"
  TOTAL=$((TOTAL + n))
done

if (( TOTAL != 5 )); then
  fail "synthetic counter wrong: got $TOTAL, expected 5 (powerfully must NOT match)"
fi
pass "ac-6.2 edge PASS (regex respects word boundaries and ignores 'powerfully')"
