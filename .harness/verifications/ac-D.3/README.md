# AC-D.3 — PLN format parity

Proves: Phase 1 documents the expected INC markdown bullet list format and
the validation-failure → Claude-PLN fallback; a happy-shaped stub response
parses; a garbage-shaped stub response fails parsing so the fallback
triggers.

## Known false-pass risks
- Parser is a local python re.findall; the production parser may differ.
  We encode the *specification*, not the implementation — PLN audit confirms
  alignment.
