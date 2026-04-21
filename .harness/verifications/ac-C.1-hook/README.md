# AC-C.1 — execute gate whitelist

Proves: call-<provider>.sh bash calls are allowed for any agent; other Bash
for non-IMP remains blocked; IMP's full write/bash capability is untouched;
integration — hook actually sources the shared provider allowlist (not
hardcoded).

## Known false-pass risks
- "Sources shared file" grep is static. Dynamic injection via 'unicorn'
  provider confirms runtime pickup.
- Restores shared file via EXIT trap; if test is killed (kill -9), the file
  may be left modified. Trap uses cp from scratch backup — resilient to
  normal interruption.
