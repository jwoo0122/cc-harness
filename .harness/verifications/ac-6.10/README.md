# AC-6.10 — All 4 principles covered, no "(partial)" hedge

Principle keyword map (lowercased, whole-word):
  P1  self-confirmation         OR  confirmation bias
  P2  interview                  AND ambiguity
  P3  pre-arranged               AND verification
  P4  persist + (cross-session OR across sessions), either order

Forbidden: `\bpartial\b` OR `\(partial\)` (hedge adjective).

happy.sh — real README.
edge.sh  — proves the hedge detector fires on (partial)/partial,
           does NOT fire on "partially" (word boundary), and the
           P4 regex accepts 4 phrasing variants.
