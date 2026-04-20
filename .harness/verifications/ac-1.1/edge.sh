#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
DOC="$ROOT/docs/iteration-layout.md"

[[ -f "$DOC" ]] || fail "docs/iteration-layout.md missing"

grep -qF '^\.iteration-[1-9][0-9]*$' "$DOC" \
  || fail "layout doc does not contain the exact regex ^\\.iteration-[1-9][0-9]*\$"
ok "regex literal present"

for bad in 'plan\.md' 'report\.md' '^.*- log\.md'; do
  if grep -qE "$bad" "$DOC"; then
    if grep -qE "^\s*[-*]\s+\`?($bad)\`?" "$DOC"; then
      fail "layout doc lists a forbidden alt filename in a bullet: matches /$bad/"
    fi
  fi
done
ok "no forbidden alt filenames in required-file bullets"

if grep -qE 'target/explore/.*\.md' "$DOC"; then
  fail "layout doc still references legacy target/explore/*.md sink"
fi
ok "no legacy target/explore sink reference"

pass "ac-1.1 edge PASS"
