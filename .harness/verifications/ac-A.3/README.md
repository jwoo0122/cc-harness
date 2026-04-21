# AC-A.3 — Measurement script + results.jsonl schema

Proves: run.sh/measure.sh exists, appends schema-valid JSON lines with
required fields, is append-only across invocations, rejects adversarial
corpus inputs safely, and respects the [0,1] invariant on rate metrics.

## Known false-pass risks
- Relies on HARNESS_BASELINE_DRY=1 path in the script. IMP must implement this
  hook; absence = edge.sh/adversarial.sh fail, which is correct signal.
- Append-only is byte-diff on the first N lines; a script that both prepends
  AND appends would evade. Acceptable: we also require the line count to grow.
