# AC-A.1 — baseline-variance/ directory + README

Proves: the experiment directory exists with a README that declares purpose,
reproduction steps, metric definitions, and corpus source; does not recycle
forbidden absolute thresholds; and keeps inputs/ ↔ README references in sync.

## Files
- happy.sh: existence + required sections (purpose/reproduction/metrics/source)
- edge.sh: non-trivial content; σ-based language; no forbidden 15pp threshold
- adversarial.sh: bidirectional sync between inputs/ and README refs

## Known false-pass risks
- Grep on "σ" alone can be satisfied by a dismissive sentence. Mitigation:
  PLN audit in Phase 1.5b should reject READMEs whose σ reference is decorative.
- `inputs/` bidirectional check passes vacuously if no files are referenced
  and none exist. AC-A.2 enforces non-empty corpus separately.
