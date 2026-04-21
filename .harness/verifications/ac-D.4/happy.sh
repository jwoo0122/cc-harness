#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
# Locate the Phase 2d region.
sec=$(awk '/^## Phase 2/{f=1} f{print} /^## Phase 3/{exit}' "$S")
[[ -n "$sec" ]] || fail "Phase 2 region not found"
# Extract the 2d subsection only (heuristic: starts at '### 2d' or mentions cross-check).
sub=$(printf '%s\n' "$sec" | awk '/^### 2d|cross[- ]check/{f=1} f{print} /^### 2e/{exit}')
[[ -n "$sub" ]] || sub="$sec"
# Forbidden: Codex / HARNESS_PLN_PROVIDER / call-codex
if printf '%s\n' "$sub" | grep -qiE 'codex|HARNESS_PLN_PROVIDER|call-codex\.sh'; then
  fail "Phase 2d region mentions Codex/HARNESS_PLN_PROVIDER — D.4 requires Claude-only"
fi
# Required: subagent_type pln
printf '%s\n' "$sub" | grep -qE 'subagent_type[[:space:]]*:[[:space:]]*"?pln"?' \
  || fail "Phase 2d does not use subagent_type: pln (Claude)"
pass "AC-D.4 happy"
