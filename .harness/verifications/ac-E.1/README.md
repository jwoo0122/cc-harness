# AC-E.1 — docs/multi-provider-dispatch.md

Proves: docs cover overview, usage (with a working fenced example),
failure modes (≥3 of 4 B.2 scenarios + D.3 format mismatch), debug tips,
and iter-5 roadmap; no unguarded 'silent fallback' language.

## Known false-pass risks
- "hits >= 3" threshold lets one scenario be glossed over. PLN audit may
  insist on 4/4; trivial to tighten.
