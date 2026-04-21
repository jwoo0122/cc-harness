#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

if grep -qE 'claude[[:space:]]+plugin[[:space:]]+install' "$F"; then
  grep -nE 'claude[[:space:]]+plugin[[:space:]]+install' "$F" >&2
  fail "README contains forbidden 'claude plugin install' CLI string"
fi
ok "no 'claude plugin install'"

if grep -qiE 'install|marketplace' "$F"; then
  if ! grep -qE '/plugin marketplace add|/plugin install' "$F"; then
    fail "README mentions install but has no /plugin marketplace add or /plugin install"
  fi
  ok "correct slash-command present"
else
  ok "README does not mention install — vacuously passes"
fi
pass "ac-6.9 happy PASS"
