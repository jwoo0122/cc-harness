# AC-A.4 — σ summary.md

Proves: summary.md carries mean/σ/95%CI/n with numeric sanity, and
mechanically encodes the rabbit-hole #6 caveat (correlated-failure /
echo-chamber / rabbit-hole 6). This is the Phase-1.5 self-amendment VER
committed to.

## Known false-pass risks
- Caveat grep is textual; a terse one-liner passes. PLN audit should insist
  on a paragraph framing + explicit iter-5+ scope pointer.
- Numeric extraction regex is loose; a column-formatted markdown table with
  decorative separators may parse quirkily.
