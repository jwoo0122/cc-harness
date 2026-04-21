# AC-B.1 — call-codex.sh contract (stdin → codex exec --json → stdout)

Proves: script exists, reads stdin verbatim, invokes `codex exec --json`,
emits JSONL-only on stdout, and treats empty stdin sanely without hanging.

## Known false-pass risks
- Stub verifies argv contains "exec" and "--json" but not their order.
  Accepted — real codex accepts either order.
- Empty-stdin behavior is permissive (reject-with-error OR pass-empty).
  If product decides one or the other, tighten this test.
