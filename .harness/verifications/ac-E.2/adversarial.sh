#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
P="$(repo_root)/.harness/experiments/baseline-variance/codex-pln-probe.md"
[[ -f "$P" ]] || fail "probe doc missing"
grep_forbidden_phrase 'we[[:space:]]+(ship|kill|adopt|reject)[[:space:]]+(codex|pln[[:space:]-]*>?[[:space:]-]*codex)' "$P" \
  || fail "probe doc prematurely declares ship/kill verdict (iter-4 is numbers-only)"
grep_forbidden_phrase 'decision[[:space:]]*:[[:space:]]*(ship|kill)' "$P" \
  || fail "probe doc contains unguarded Decision: ship/kill line"
grep -qiE 'iter[[:space:]-]*5|iteration[[:space:]-]*5' "$P" \
  || fail "probe doc does not defer conclusion to iter-5"
pass "AC-E.2 adversarial"
