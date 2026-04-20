#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch md-section-edge)"
trap 'cleanup_scratch "$SCRATCH"' EXIT

cat >"$SCRATCH/fixture.md" <<'MD'
## Real

```bash
echo "## Pretend heading 1"
```

~~~
## Pretend heading 2
~~~

```python
# triple backtick inside a python comment not relevant
print("## Pretend heading 3")
```

body continues.
## Next
must not appear
MD

OUT="$(md_section "$SCRATCH/fixture.md" "## Real")"
for fake in 'Pretend heading 1' 'Pretend heading 2' 'Pretend heading 3'; do
  echo "$OUT" | grep -qF "$fake" || fail "lost fenced line: $fake"
done
ok "three flavours of fenced fake-headings preserved"

if echo "$OUT" | grep -q '^## Next$'; then
  fail "bled past next section"
fi
ok "stopped at real ## Next"

pass "ac-C.1 edge PASS"
