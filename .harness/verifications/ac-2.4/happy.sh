#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"

CANDIDATES=(
  "$ROOT/skills/explore/SKILL.md"
  "$ROOT/agents/imp.md"
  "$ROOT/docs/iteration-layout.md"
)

NUM_HIT=""
MARKER_HIT=""
for f in "${CANDIDATES[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -qE '\b2,?000\b' "$f" && grep -qiE 'token' "$f"; then
    NUM_HIT="${NUM_HIT}${f}\n"
  fi
  if grep -qF '<!-- truncated -->' "$f"; then
    MARKER_HIT="${MARKER_HIT}${f}\n"
  fi
done

[[ -n "$NUM_HIT" ]]    || fail "no doc specifies the 2,000 token limit"
ok "2,000-token limit specified"
[[ -n "$MARKER_HIT" ]] || fail "no doc specifies the exact <!-- truncated --> marker"
ok "<!-- truncated --> marker specified"

pass "ac-2.4 happy PASS"
