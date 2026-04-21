# AC-6.2 — Hype-lexicon hits ≤ 4

Proves README.md contains ≤ 4 whole-word, case-insensitive hits
from the 12-token hype list (powerful, seamless, revolutionary,
magical, effortless, blazing, cutting-edge, game-chang*, simply,
just works, robust, elegant, beautiful).

happy.sh — counts hits in real README.
edge.sh  — regression test proving the counter respects word
           boundaries (`powerfully` must NOT increment the count)
           and case-insensitivity.

Current README has ~29 hits; expected FAIL pre-INC-1, PASS after.
