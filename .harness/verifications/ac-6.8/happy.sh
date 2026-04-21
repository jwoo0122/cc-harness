#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

if grep -qE '\.claude/hooks/[A-Za-z0-9_.-]+\.py' "$F"; then
  grep -nE '\.claude/hooks/[A-Za-z0-9_.-]+\.py' "$F" >&2
  fail "README references non-existent .claude/hooks/*.py path(s)"
fi
ok "no .claude/hooks/*.py references"

MISSING=0
while IFS= read -r path; do
  clean="$(printf '%s' "$path" | sed -E 's/^[^a-zA-Z0-9_./-]*//; s/[^a-zA-Z0-9_./-]*$//')"
  if [[ -n "$clean" && ! -e "$ROOT/$clean" ]]; then
    echo "MISSING: $clean" >&2
    MISSING=$((MISSING + 1))
  fi
done < <(grep -oE 'skills/[A-Za-z0-9_./-]+' "$F" || true)

if (( MISSING > 0 )); then
  fail "$MISSING skills/* path(s) referenced in README do not exist"
fi
pass "ac-6.8 happy PASS"
