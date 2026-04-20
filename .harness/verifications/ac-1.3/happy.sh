#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"

[[ -f "$ROOT/.gitignore" ]] || fail ".gitignore missing"
grep -qxF '.iteration-*/' "$ROOT/.gitignore" \
  || grep -qxF '.iteration-*' "$ROOT/.gitignore" \
  || fail ".gitignore does not contain the pattern '.iteration-*/'"
ok ".gitignore contains the iteration glob"

DOC="$ROOT/docs/iteration-layout.md"
[[ -f "$DOC" ]] || fail "docs/iteration-layout.md missing"
grep -qiE 'opt[- ]?in|tracked|force[- ]?add|git add -f|!\.iteration' "$DOC" \
  || fail "layout doc does not describe opt-in tracking for iteration dirs"
ok "opt-in tracking procedure documented"

pass "ac-1.3 happy PASS"
