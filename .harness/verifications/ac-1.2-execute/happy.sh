#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
SKILL="$ROOT/skills/execute/SKILL.md"
[[ -f "$SKILL" ]] || fail "skills/execute/SKILL.md missing"

SECTION="$(md_section "$SKILL" "## Phase 0" || true)"
if [[ -z "$SECTION" ]]; then
  SECTION="$(awk '/^## .*Phase 0/,/^## /{ if(/^## /&&NR>1&&!/Phase 0/)exit; print }' "$SKILL")"
fi
[[ -n "$SECTION" ]] || fail "could not locate Phase 0 section in execute SKILL.md"
ok "Phase 0 section located"

echo "$SECTION" | grep -qF '^\.iteration-[1-9][0-9]*$' \
  || fail "Phase 0 does not reference the directory-name regex"
ok "regex referenced in Phase 0"

echo "$SECTION" | grep -qiE 'hard error|halt|must abort|must stop|에러.*중단|중단한다|abort' \
  || fail "Phase 0 does not instruct a hard-error abort on invalid dir name"
ok "Phase 0 instructs hard-error abort"

if echo "$SECTION" | grep -qiE 'silently (skip|continue)|warn and continue|best[- ]effort'; then
  fail "Phase 0 contains silent-skip language"
fi
ok "no silent-skip language"

pass "ac-1.2-execute happy PASS"
