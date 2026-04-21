#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

H2_LINES=()
while IFS= read -r line; do H2_LINES+=("$line"); done < <(awk '
  BEGIN { in_fence=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; next }
  !in_fence && /^## / { print NR }
' "$F")

N=${#H2_LINES[@]}
ok "H2 count = $N"

if (( N != 4 )); then
  pass "ac-6.11 trivial PASS (H2 count $N != 4)"
fi

TOTAL_LINES="$(wc -l < "$F" | tr -d '[:space:]')"

COUNTS=()
for i in "${!H2_LINES[@]}"; do
  start="${H2_LINES[$i]}"
  nexti=$((i + 1))
  if (( nexti < N )); then
    end=$(( H2_LINES[$nexti] - 1 ))
  else
    end=$TOTAL_LINES
  fi
  body_wc="$(awk -v s="$start" -v e="$end" 'NR>s && NR<=e' "$F" | wc -w | tr -d '[:space:]')"
  COUNTS+=("$body_wc")
  ok "H2[$i] @L$start..L$end body words = $body_wc"
done

STDDEV="$(printf '%s\n' "${COUNTS[@]}" | awk '
  { sum+=$1; sq+=$1*$1; n++ }
  END {
    if (n==0) { print 0; exit }
    mean = sum/n
    var  = (sq/n) - (mean*mean)
    if (var < 0) var = 0
    printf "%.2f", sqrt(var)
  }')"
ok "section-body stddev = $STDDEV (threshold 25)"

OK="$(awk -v s="$STDDEV" 'BEGIN { print (s >= 25) ? "1" : "0" }')"
if [[ "$OK" != "1" ]]; then
  fail "H2 count is 4 but section-body stddev $STDDEV < 25 (parallel-matrix risk)"
fi
pass "ac-6.11 happy PASS (stddev=$STDDEV)"
