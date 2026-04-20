#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
IMP="$ROOT/agents/imp.md"
[[ -f "$IMP" ]] || fail "agents/imp.md missing"

grep -qF 'brief.md.tmp' "$IMP" \
  || fail "imp.md does not mention brief.md.tmp"
ok "brief.md.tmp referenced"

grep -qiE 'atomic( rename| write)|rename\(2\)|mv .*brief\.md|원자적' "$IMP" \
  || fail "imp.md does not describe atomic rename"
ok "atomic-rename semantics present"

pass "ac-2.3 happy PASS"
