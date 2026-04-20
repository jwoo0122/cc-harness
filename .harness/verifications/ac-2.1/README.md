# AC-2.1 verification bundle

Proves: explore Phase 5 names `.iteration-N/brief.md` as target, and hook scripts are
byte-identical to their pre-iteration baseline (SHA256).

## Pre-implementation expectation
- happy.sh fails (Phase 5 not rewritten).
- edge.sh passes if hooks unmodified, fails on any byte change.
