# Codex PLN probe — iter-4 re-measure

> Single-probe measurement with `HARNESS_PLN_PROVIDER=codex` against the iter-4 baseline-variance corpus (3 fixtures × 5 iterations, mock mode). **This is a scouting probe, not a ship/kill decision. Conclusions deferred to iter-5 after ≥5 diverse runs.**

## Context

- **Provider**: OpenAI Codex CLI via `.harness/scripts/call-codex.sh`
- **Mode**: `mock` (deterministic fixture-driven, not a live /explore)
- **Corpus**: 3 archived debate fixtures (iter-1-structural, iter-2-tech-debt, iter-4-scoping)
- **Iterations per input**: 5

## Claude baseline (from summary.md, mock-mode rows only)

<!-- Populated from results.jsonl stance_agreement_rate metric, provider=claude, mode=mock -->
- Sample count (n): 15
- Mean: 0.3737
- σ (stdev): 0.2343
- 95% CI: [0.2551, 0.4923]

Per-input (from `summary.md`):

| Input | n | mean | σ |
|-------|---|------|----|
| iter-1-structural.md | 5 | 0.4864 | 0.2925 |
| iter-2-tech-debt.md | 5 | 0.3288 | 0.2543 |
| iter-4-scoping.md | 5 | 0.3058 | 0.1334 |

## Codex probe (single-value from this invocation)

- Sample count (n): 15
- Mean: 0.4738
- σ (stdev): 0.3033 (informational; formula below uses claude σ as reference)

## Delta formula

```
delta_sigmas = |codex_mean - claude_mean| / claude_sigma
```

- Calculated: |0.4738 − 0.3737| / 0.2343 = `0.43` σ

## Interpretation (iter-4: descriptive only)

- `delta_sigmas < 1.0`: codex output statistically indistinguishable from claude under this metric+corpus
- `1.0 <= delta_sigmas < 2.0`: noise-range; not conclusive
- `delta_sigmas >= 2.0`: potential signal — iter-5 confirmatory run required with larger n

**iter-4 verdict: no ship/kill decision. Observed delta (0.43σ) falls in the "indistinguishable" band under this mock-mode corpus. This probe establishes that the codex dispatch path executes end-to-end without infrastructure failure, and that per-row provider attribution works in `results.jsonl`. Quantitative comparison with Claude baseline requires more runs (iter-5).**

## Known caveats

- Mock mode means both Claude and Codex rows are deterministic hash-based pseudorandom metrics — their delta reflects hashing differences, not actual model behavior. Iter-5 must use real `/explore` invocations with `HARNESS_BASELINE_MODE=real` for meaningful comparison.
- Single-probe σ (n=15 for claude baseline) is under-powered; CI is wide. Iter-5 should scale to n=30+.
- The rabbit-hole #6 limitation (correlated frontier-model training-bias) applies — provider diversity doesn't protect against shared training-data blindspots on specific topics. Detection requires cross-provider ablation at scale.

## Reproduction

```bash
HARNESS_BASELINE_MODE=mock HARNESS_PLN_PROVIDER=codex \
  bash .harness/experiments/baseline-variance/run.sh
```

After run: `results.jsonl` will have additional rows tagged `provider: codex`; `summary.md` will reflect pooled statistics.
