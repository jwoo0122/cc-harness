# AC-B.2 — Preflight auth (loud-fail)

Proves: each of the four preflight failure modes (missing binary, missing
token, quota, network) exits non-zero, writes a branded warning to stderr,
and leaves stdout empty. Includes static grep for `|| true` silent-swallow.

## Known false-pass risks
- We accept any exit != 0; criteria says exit 2. Tighten to == 2 once PLN
  confirms the exact code policy across preflight/timeout/remote-fail.
- "missing token" is detected by unsetting the 3 known env var names; if the
  script uses a fourth, test passes vacuously. Kept simple by design.
