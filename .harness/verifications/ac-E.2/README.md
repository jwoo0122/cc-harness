# AC-E.2 — Re-measure with HARNESS_PLN_PROVIDER=codex

Proves: codex-pln-probe.md exists with metric content; results.jsonl carries
a provider="codex" (or pln_provider="codex") record with schema_version;
probe doc defers ship/kill to iter-5 (scope discipline).

## Known false-pass risks
- The check for a codex record in results.jsonl could pass from a previous
  test run; caller should clear or distinguish via run_id. PLN audit may
  require a run_id check in iter-5.
- Forbidden-phrase check uses the lib's guard-tolerant grep; a hedged
  sentence like "we could ship codex, but we won't" passes — intentional.
