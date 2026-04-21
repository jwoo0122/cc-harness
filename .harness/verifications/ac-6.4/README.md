# AC-6.4 — Tables ≤ 1

A table = run of ≥ 2 consecutive lines matching `^\|.*\|$` that are
NOT inside a fenced code block.

happy.sh — counts tables in real README (limit 1).
edge.sh  — fixtures prove: blockquote `>` lines with pipes are not
           counted; fenced code blocks are not counted; one real
           table counts as 1.

Current README has 3 tables; expected FAIL pre-INC-1.
