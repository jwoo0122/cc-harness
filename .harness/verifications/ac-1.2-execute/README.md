# AC-1.2 (execute side) verification bundle

Proves: `skills/execute/SKILL.md` Phase 0 instructs hard-error abort on invalid
iteration dir with the regex referenced.

edge.sh was intentionally dropped in spec v3 — happy.sh's behavioral check is
sufficient; textual-order proxy not worth maintaining.

## Pre-implementation expectation
happy.sh fails until Phase 0 is rewritten.
