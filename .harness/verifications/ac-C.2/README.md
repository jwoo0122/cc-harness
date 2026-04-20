# AC-C.2 — grep_forbidden_phrase, declaration-aware

Proves: declaration keywords (must not / do not / forbidden / 금지 / never / shall not / 禁止 / don't / cannot / should not / may not / no silent / no auto / no warn) suppress same-line matches; EC=1 on unguarded match with FILENAME:LINENO:line; EC=0 when all guarded.

**Known limitation** (locked by adversarial.sh): line-wide heuristic — a line that discusses a declaration keyword AND commits the forbidden phrase is treated as guarded.
