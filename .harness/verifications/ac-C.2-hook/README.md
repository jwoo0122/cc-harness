# AC-C.2 — explore whitelist

Proves: explore's block-mutating.sh allows only exact `.harness/scripts/
call-<provider>.sh` invocations from the shared allowlist; Edit/other Bash
remain blocked; the hook is dynamically wired to the same shared file as
gate-mutating.sh (integration self-amendment).

## Known false-pass risks
- `sed` removal by commenting-out is fragile if the allowlist uses a data
  format we didn't anticipate. PLN must ensure the shared file uses a
  consistent grep-able form ('codex' as a token on its own line or in an array).
- If 'pln' is not a legitimate explore agent_type, the probe should use
  'skp'/'opt'/etc.; both should work since explore treats all non-IMP equally.
