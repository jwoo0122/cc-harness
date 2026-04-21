# AC-6.3 — Installer block ≤ 15 lines

Any contiguous install/usage block spans at most 15 lines. Blocks
are detected two ways:
  1. H2/H3 headings matching `Install|Use it|Usage`. Terminator matches
     next H2 heading only (exactly `^## `, not H3+); sub-section H3s
     inside Install are part of the block.
  2. Contiguous non-blank runs containing `/plugin marketplace add`
     or `/plugin install`.

happy.sh — real README check.
edge.sh  — synthetic fixtures proving span measurement is heading-
           bounded and blank-bounded with no off-by-one.

Current README's Install section is ~106 lines; expected FAIL pre-INC-1.
