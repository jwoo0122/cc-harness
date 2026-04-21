# AC-D.1 — Phase 1 PLN dispatch branch

Proves: SKILL.md Phase 1 documents a real if/else branch on
HARNESS_PLN_PROVIDER=codex → call-codex.sh, with Claude PLN as the default;
branch is not accidentally replicated into Phase 2d (enforced by D.4 peer).

## Known false-pass risks
- md_section relies on an exact heading literal. If PLN renames Phase 1 the
  awk-fallback in adversarial.sh still catches the 2d block; happy.sh does not.
  Accept: PLN audit flags heading drift.
