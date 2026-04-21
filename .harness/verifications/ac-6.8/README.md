# AC-6.8 — No false hook reference

Two checks:
  1. README.md contains zero `\.claude/hooks/[^ ]+\.py` substrings
     (this is the known-broken path family — no Python hooks exist
     in this repo).
  2. Every `skills/...` path referenced in README.md resolves to
     a real file or directory under the repo root.

Current README may reference non-existent paths; check outcome
determines whether INC-1 needs path fixes.
