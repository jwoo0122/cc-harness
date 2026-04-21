# AC-6.5 — First-person count = 0 (outside code fences)

Counts word-boundary, case-insensitive matches of {I, we, our, my, us}
in README.md after stripping fenced code blocks.

happy.sh — real README (must be 0).
edge.sh  — synthetic fixtures prove fence-stripping works and real
           prose pronouns are still detected.
