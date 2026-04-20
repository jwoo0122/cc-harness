#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
DOC="$ROOT/docs/iteration-layout.md"
[[ -f "$DOC" ]] || fail "docs/iteration-layout.md missing"

grep -qiE 'gitleaks|trufflehog|detect-secrets|secret[- ]?scan' "$DOC" \
  || fail "layout doc does not mention a secret scanner"
ok "secret scanner referenced"

grep -qiE 'pre[- ]?commit|before (commit|tracking|push)|커밋 전|추적 전' "$DOC" \
  || fail "layout doc does not place the scan in a pre-commit / before-commit context"
ok "pre-commit timing recommended"

pass "ac-1.4 happy PASS"
