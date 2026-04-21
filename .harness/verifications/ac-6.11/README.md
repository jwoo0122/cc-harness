# AC-6.11 — Prose-matrix proxy (heading symmetry)

Proxy for the SKP deletion test: if README has exactly 4 H2
sections, the population stddev of their body word counts must
be ≥ 25. Otherwise the AC passes trivially.

## Known false-pass risk
This proxy does NOT detect parallel prose structure when the
document has 3 or 5+ H2s; those trivially pass. Per PLN's
locked plan INC-1 fixes H2 count at 4, so this risk is bounded
in practice — but a future edit could collapse a principle into
an H3 (reducing to 3 H2s) and bypass the check. PR review must
confirm H2 count == 4; the automated proxy cannot.

A second false-pass surface: four sections of sizes
[10, 50, 50, 90] yield stddev ≈ 28 (passes) yet could still
feel "matrixy" in prose. The SKP qualitative deletion test is
retained as a PR-review checklist item and is not automated.

happy.sh        — real README measurement.
adversarial.sh  — stddev math calibration on synthetic fixtures
                  + documentation that 3-H2 case trivially passes.
