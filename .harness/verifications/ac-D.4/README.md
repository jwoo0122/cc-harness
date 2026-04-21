# AC-D.4 — Phase 2d Claude-only

Proves: Phase 2d cross-check region explicitly uses subagent_type=pln and
does NOT reference Codex / HARNESS_PLN_PROVIDER / call-codex.sh. Whole-file
cross-reference scan confirms no sneaky association.

## Known false-pass risks
- Section extraction is heuristic (no stable anchor in current SKILL.md).
  Falls back to the whole Phase 2 region, which is conservative — may
  falsely fail if 'codex' is mentioned outside the 2d subsection; that is
  acceptable over-caution for D.4.
