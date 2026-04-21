#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

WC="$(wc -w < "$F" | tr -d '[:space:]')"
ok "README.md word count = $WC (limit 550)"

if (( WC > 550 )); then
  fail "README.md word count $WC exceeds 550"
fi
pass "ac-6.1 happy PASS (wc=$WC)"
