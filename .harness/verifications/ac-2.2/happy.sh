#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"

CANDIDATES=(
  "$ROOT/skills/explore/SKILL.md"
  "$ROOT/skills/explore/templates/brief.md"
  "$ROOT/docs/iteration-layout.md"
)
FOUND=""
for f in "${CANDIDATES[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -qF '## Bet' "$f" \
     && grep -qF '## Appetite' "$f" \
     && grep -qF '## Boundaries / Non-goals' "$f" \
     && grep -qF '## Risk-flagged rabbit-holes' "$f"; then
    FOUND="$f"
    break
  fi
done

[[ -n "$FOUND" ]] || fail "no file contains all four required section headers"
ok "all four headers present in $FOUND"

pass "ac-2.2 happy PASS"
