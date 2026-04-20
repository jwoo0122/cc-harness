#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"

REFERRERS=(
  "$ROOT/skills/execute/SKILL.md"
  "$ROOT/skills/explore/SKILL.md"
  "$ROOT/docs/iteration-layout.md"
)

HITS=0
for f in "${REFERRERS[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -qF 'agents/imp.md' "$f" && grep -qiE 'atomic|tmp|rename|원자적' "$f"; then
    HITS=$((HITS + 1))
  fi
done

(( HITS >= 1 )) || fail "no file cross-references agents/imp.md with atomic-write context"
ok "cross-reference present in $HITS file(s)"

pass "ac-2.3 edge PASS"
