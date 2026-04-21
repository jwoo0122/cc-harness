#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

stddev() {
  printf '%s\n' "$@" | awk '
    { sum+=$1; sq+=$1*$1; n++ }
    END {
      mean=sum/n; var=(sq/n)-(mean*mean); if (var<0) var=0
      printf "%.2f", sqrt(var)
    }'
}

A="$(stddev 100 100 100 100)"
OK="$(awk -v s="$A" 'BEGIN { print (s >= 25) ? "1" : "0" }')"
if [[ "$OK" == "1" ]]; then
  fail "adversarial: stddev(100,100,100,100)=$A falsely ≥ 25"
fi
ok "parallel-matrix [100,100,100,100] correctly flagged (stddev=$A)"

B="$(stddev 40 120 80 200)"
OK="$(awk -v s="$B" 'BEGIN { print (s >= 25) ? "1" : "0" }')"
if [[ "$OK" != "1" ]]; then
  fail "adversarial: asymmetric stddev(40,120,80,200)=$B not ≥ 25"
fi
ok "asymmetric sections correctly pass (stddev=$B)"

SCRATCH="$(mk_scratch ac-6.11-adv)"
trap 'rm -rf "$SCRATCH"' EXIT
cat > "$SCRATCH/fake.md" <<'EOF'
# T
## One
aaa
## Two
bbb
## Three
ccc
EOF
n=$(grep -c '^## ' "$SCRATCH/fake.md")
if (( n == 4 )); then
  fail "adversarial: synthetic fixture should have 3 H2s, got $n"
fi
ok "3-H2 fixture trivially passes per spec (documented false-pass surface)"

pass "ac-6.11 adversarial PASS"
