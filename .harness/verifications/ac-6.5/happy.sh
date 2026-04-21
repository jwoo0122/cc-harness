#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

STRIPPED="$(awk '
  BEGIN { in_fence=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; next }
  { if (!in_fence) print }
' "$F")"

COUNT="$(printf '%s\n' "$STRIPPED" | grep -oiE '\b(I|we|our|my|us)\b' | wc -l | tr -d '[:space:]' || true)"

ok "first-person (non-fenced) count = $COUNT (expected 0)"
if (( COUNT != 0 )); then
  printf '%s\n' "$STRIPPED" | grep -niE '\b(I|we|our|my|us)\b' | head -20 >&2 || true
  fail "first-person pronouns found: $COUNT"
fi
pass "ac-6.5 happy PASS (first-person=0)"
