# Baseline Variance Experiment

## Purpose
Measure within-provider (Claude-only) stance-agreement variance across repeated runs of the `/explore` skill, to establish a σ baseline against which future multi-provider configurations (iter-5+) can be evaluated via "delta > 2σ" threshold.

## Metrics
- **stance-agreement rate**: per persona-pair, fraction of debates where both personas' Round-3 final recommendations align on the decisive decision point.
- **Round-3 surviving-recommendation consistency**: cosine similarity of recommendation text across N repetitions of the same input.

## Reproduction
1. `bash run.sh HARNESS_BASELINE_MODE=mock` — runs 5 mock iterations per input (fast, deterministic fixtures).
2. `bash run.sh HARNESS_BASELINE_MODE=real` — runs 5 live /explore invocations per input (deferred to INC-8 for a single-shot probe).
3. Results stream to `results.jsonl` append-only.
4. `bash summarize.sh` → emits `summary.md` with mean, σ, 95% CI.

## Inputs

See `inputs/manifest.json` for the 3 archived-debate fixtures chosen as representative corpus. Each is content-hashed (sha256) to detect accidental mutation. Source debates selected for topic diversity (structural / methodological / scoping).

The committed fixtures are:
- `inputs/iter-1-structural.md` — sourced from `.iteration-1-criteria.md` (structural: iteration-1 explore→execute closed-loop foundation debate)
- `inputs/iter-2-tech-debt.md` — sourced from `.iteration-2-criteria.md` (tech-debt: iteration-2 batch-2/3 adversarial harness + VER helper improvements debate)
- `inputs/iter-4-scoping.md` — sourced from `.iteration-4-criteria.md` (scoping: iter-4 multi-provider persona mapping, informed by the meta-debate of April 2026)

## Known limitations (rabbit-hole #6 from iter-4 synthesis)

This experiment measures within-provider variance only. It **cannot** detect "persona collapse under correlated provider failure" — the risk that all frontier models share a training-data bias on specific topics (AI safety, recent frameworks) and converge to an echo chamber regardless of provider. Provider diversity is zero protection against this class. Detection requires cross-provider ablation, out-of-scope for iter-4 but seeded for iter-5+.

## iter-5 roadmap
- Add `HARNESS_PLN_PROVIDER=codex` ablation arm.
- Add correlated-error metric (citation Jaccard per Lin et al. 2025 arXiv:2506.07962).
- Scale corpus to ≥5 diverse debates.
