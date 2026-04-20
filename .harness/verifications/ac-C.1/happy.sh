#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch md-section)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

cat >"$SCRATCH/fixture.md" <<'MD'
## Real
paragraph before the fence.

```
## Fake inside fenced block — must NOT end the section
more fenced content
```

paragraph after the fence, still inside Real.
## Next
content of next section — must NOT appear in output.
MD

OUT="$(md_section "$SCRATCH/fixture.md" "## Real")"
[[ -n "$OUT" ]] || fail "md_section returned empty"

echo "$OUT" | grep -q '^## Real$'       || fail "heading missing from output"
echo "$OUT" | grep -q 'Fake inside'     || fail "fenced-fake content was dropped"
echo "$OUT" | grep -q 'after the fence' || fail "post-fence paragraph missing"

if echo "$OUT" | grep -q '^## Next$'; then
  fail "md_section bled past the next top-level heading"
fi
if echo "$OUT" | grep -q 'content of next section'; then
  fail "md_section leaked next-section body"
fi

ok "fence-aware extraction correct"
pass "ac-C.1 happy PASS"
