# [0.5.0](https://github.com/jwoo0122/cc-harness/compare/v0.4.0...v0.5.0) (2026-04-22)


### Features

* cross-model seats with Codex peer subagent dispatch ([#5](https://github.com/jwoo0122/cc-harness/issues/5)) ([f53ee22](https://github.com/jwoo0122/cc-harness/commit/f53ee22a020d15c37bbefd6ddb9e541ce80f8ebc))

# 0.5.0 (pending)

### Features

* Cross-model role separation. SKP (/explore) and VER (/execute) now run on the Codex peer model via `codex:codex-rescue` peer-subagent dispatch, not Claude. Plus a dedicated Codex adversarial-review round at the end of `/execute` Phase 1. Planner / Implementer / Optimist / Pragmatist / Empiricist stay on Claude. Rationale and mapping: `docs/codex-peer-integration.md`.
* Fallback contract. When Codex is unreachable, `/explore` falls back to `skp-fallback` and `/execute` to `ver-fallback`, both annotating the run as mono-model. The adversarial review round does NOT fall back to Claude — it annotates and proceeds, because the round exists specifically to avoid Claude self-grading.

### Breaking changes

* `HARNESS_PLN_PROVIDER=codex` env flag removed. The iter-4 subprocess wrapper (`skills/_shared/call-codex.sh`) and the provider allow-list (`skills/_shared/_provider-allowlist.sh`) are gone, replaced by peer-subagent dispatch. Users who set the env var should unset it and rely on the default cross-model seats.
* `agents/skp.md` → `agents/skp-fallback.md`; `agents/ver.md` → `agents/ver-fallback.md`. They remain invocable but are no longer the default SKP / VER seats.
* `docs/multi-provider-dispatch.md` replaced by `docs/codex-peer-integration.md`.

# [0.4.0](https://github.com/jwoo0122/cc-harness/compare/v0.3.0...v0.4.0) (2026-04-21)


### Features

* Multi-provider PLN dispatch (baseline + PLN→Codex) ([#3](https://github.com/jwoo0122/cc-harness/issues/3)) ([92a6d3c](https://github.com/jwoo0122/cc-harness/commit/92a6d3cc741a379534a3bbf6c0fdc73c1223c684)), closes [#6](https://github.com/jwoo0122/cc-harness/issues/6)

# [0.3.0](https://github.com/jwoo0122/cc-harness/compare/v0.2.0...v0.3.0) (2026-04-20)


### Features

* add EMP (Empiricist) as 4th explore persona ([c743bc2](https://github.com/jwoo0122/cc-harness/commit/c743bc2c43be7dacae0d7ca0751334ca392414d2))

# [0.2.0](https://github.com/jwoo0122/cc-harness/compare/v0.1.1...v0.2.0) (2026-04-20)


### Features

* add verification-first Phase 1.5 to execute skill ([83431be](https://github.com/jwoo0122/cc-harness/commit/83431be7e8e7b9d245b47eb6767519e61c509a49))

## [0.1.1](https://github.com/jwoo0122/cc-harness/compare/v0.1.0...v0.1.1) (2026-04-18)


### Bug Fixes

* use './' for marketplace plugin source ([5190066](https://github.com/jwoo0122/cc-harness/commit/519006675121815c6fe12cbc64b00c9ed56703be))
