#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
if grep -iE '2d.*codex|codex.*2d' "$S"; then
  fail "Phase 2d associated with Codex somewhere in SKILL.md"
fi
pass "AC-D.4 adversarial"
