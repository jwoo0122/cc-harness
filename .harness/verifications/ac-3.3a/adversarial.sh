#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"

PATTERNS=(
  'ignore previous instructions'
  'override your role'
  'execute this instruction'
  'disregard the above'
  'you are now a'
  'system prompt:'
)

ANY_UNGUARDED=0
for p in "${PATTERNS[@]}"; do
  if grep_forbidden_phrase "$p" "$SKILL"; then
    :
  else
    ANY_UNGUARDED=1
    echo "UNGUARDED injection-seed phrase detected: '$p'" >&2
  fi
done

if [[ "$ANY_UNGUARDED" -ne 0 ]]; then
  fail "SKILL.md contains unguarded injection-seed phrases"
fi

ok "no unguarded injection-seed phrases in SKILL.md"
pass "ac-3.3a adversarial PASS"
