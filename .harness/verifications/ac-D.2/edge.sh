#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
# We REQUIRE that any mention of "silent fallback" is guarded by a negation
# (must not, forbidden, never, 금지). grep_forbidden_phrase exits 1 when an
# unguarded match exists.
if ! grep_forbidden_phrase 'silent[[:space:]]+fallback' "$S"; then
  fail "SKILL.md contains unguarded 'silent fallback' phrase"
fi
if ! grep_forbidden_phrase 'silently[[:space:]]+fall[[:space:]-]?back' "$S"; then
  fail "SKILL.md contains unguarded 'silently fall back' phrase"
fi
pass "AC-D.2 edge"
