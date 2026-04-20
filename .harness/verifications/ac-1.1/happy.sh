#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../_shared/lib.sh
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
DOC="$ROOT/docs/iteration-layout.md"

[[ -f "$DOC" ]] || fail "docs/iteration-layout.md missing"
ok "layout doc exists"

for name in brief.md verify-report.md decision-log.md; do
  grep -qF "$name" "$DOC" || fail "layout doc does not mention required file: $name"
  ok "mentions $name"
done

grep -qiE '필수|mandatory|required|must (exist|be present|contain)' "$DOC" \
  || fail "layout doc does not assert the three files are required"
ok "layout doc marks the three files as required"

pass "ac-1.1 happy PASS"
