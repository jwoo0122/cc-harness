# AC-C.3 — strict provider regex

Proves: whitelist is anchored exact-match `^\.harness/scripts/call-[a-z]+\.sh$`
and blocks ≥7 bypass attempts (traversal, absolute path, suffix drift,
unicode homoglyph, case variation, command chaining, cmd-substitution).
Providers in shared allowlist correspond to real scripts.

## Known false-pass risks
- Homoglyph test uses Cyrillic 'а'; real attackers have dozens more. Test
  covers one representative; PLN may request expansion.
- "No phantom provider" check is focused on 'codex' for iter-4; iter-5
  expansion must extend the presence check.
