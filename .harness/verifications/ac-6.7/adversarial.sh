#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

bigrams() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9 \n-' ' ' \
    | awk '{for (i=1; i<NF; i++) print $i "_" $(i+1)}' | sort -u
}

A="Role separation, with pre-arranged verification."
B="role separation; pre-arranged verification is required."
SHARED_N="$(comm -12 <(bigrams "$A") <(bigrams "$B") | grep -c . || true)"
if (( SHARED_N < 2 )); then
  fail "punctuation-variant strings should share ≥2 bigrams (got $SHARED_N)"
fi
ok "punctuation-robust ($SHARED_N shared)"

C="Totally different wording about seagulls and lighthouses."
SHARED_N2="$(comm -12 <(bigrams "$A") <(bigrams "$C") | grep -c . || true)"
if (( SHARED_N2 >= 2 )); then
  fail "unrelated strings reported $SHARED_N2 shared bigrams (false positive)"
fi
pass "ac-6.7 adversarial PASS (bigram extractor well-calibrated)"
