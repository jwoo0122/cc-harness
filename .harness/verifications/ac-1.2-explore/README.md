# AC-1.2 (explore side) verification bundle

Proves: `skills/explore/SKILL.md` Phase 5 instructs a hard-error abort on invalid
iteration-dir names, and the regex literal in the doc correctly accepts/rejects
the canonical good/bad sample set (5 good + 12 bad).

## Pre-implementation expectation
Both fail — Phase 5 lacks the regex + hard-error wording.
