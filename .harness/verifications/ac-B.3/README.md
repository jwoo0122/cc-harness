# AC-B.3 — Timeout (default 60s, env override, exit 3)

Proves: default 60s literal exists, timeout produces exit 3 within the
budget, HARNESS_CODEX_TIMEOUT override is honored, pathological values
(0, negative) are rejected rather than silently disabling the budget.

## Known false-pass risks
- "60 literal in source" can be satisfied by an unrelated number. PLN audit
  confirms it's wired to the timeout path.
- Outer `timeout 10` assumes GNU/coreutils `timeout` present. macOS: install
  via `brew install coreutils` or use `gtimeout`. Fallback handled by the
  existence of `timeout` on CI images.
