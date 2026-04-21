# AC-B.4 — Injection safety (stdin-only, redaction)

Proves: prompts flow only via stdin (not ARGV), shell metachars have no
side effects, byte-identical forwarding under random adversarial inputs,
API-key-shape strings do not persist to stderr or log files.

## Known false-pass risks
- Redaction test only inspects stderr + `.harness/logs/`. If IMP invents a
  new sink (e.g. /tmp), secrets could leak there. Phase 2d spot-check
  recommended.
- Property test uses 30 cases; coverage-limited. Expand if a regression appears.
