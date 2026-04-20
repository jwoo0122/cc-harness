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

# 임시 파일에 SECTION 저장 후 grep_forbidden_phrase로 검사 (declaration-context suppression).
SEC_TMP="$(mktemp /tmp/ac-1.2-execute.XXXXXX)"
trap 'rm -f "$SEC_TMP"' EXIT
printf '%s\n' "$SECTION" > "$SEC_TMP"
if grep_forbidden_phrase 'silently (skip|continue)|warn and continue|best[- ]effort' "$SEC_TMP"; then
  # grep_forbidden_phrase: EC=0 → clean (unguarded 매치 없음), EC=1 → unguarded 매치 발견.
  ok "no unguarded silent-skip language"
else
  fail "Phase 0 contains unguarded silent-skip language"
fi

pass "ac-1.2-execute happy PASS"
