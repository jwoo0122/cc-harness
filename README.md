# cc-harness

Two-mode cognitive harness for **Claude Code** — structured thinking protocols that eliminate self-affirmation bias.

This is the Claude Code port of [`@jwoo0122/harness`](https://github.com/jwoo0122/harness) (the pi-agent package). Same protocols, re-implemented as Claude Code skills + subagents + hooks.

## What this is

| Mode | Skill | Personas / Roles | Purpose |
|------|-------|------------------|---------|
| **Diverge** | `/explore` | 🔴 OPT · 🟡 PRA · 🟢 SKP · 🔵 EMP | 4-persona debate to push boundaries and find options |
| **Converge** | `/execute` | 📋 PLN · 🔨 IMP · ✅ VER | 3-role mutual verification to ship correct code |

### Why role separation?

Single-agent loops suffer from **self-affirmation bias** — the same context that writes code also evaluates whether the code is correct. The harness forces structured separation:

- **Explore**: four emotional lenses run as **isolated subagents** (separate context windows, read-only tools). No unanimous Round-1 agreement allowed. Unsupported claims are struck.
- **Execute**: three professional roles run as isolated subagents with **role-restricted tools**. The Implementer cannot mark its own ACs as passed — only the Verifier can. The Verifier cannot write code. The Planner cannot run tests.

Enforcement is **structural**, not stylistic — `PreToolUse` hooks block the wrong role from using the wrong tool, including subagent calls. You can't accidentally bypass it by "just trying" — the hook will exit 2.

## Layout

```
cc-harness/
├── README.md
├── .claude-plugin/
│   ├── plugin.json               # plugin manifest (name, version, metadata)
│   └── marketplace.json          # single-plugin marketplace catalog
├── skills/
│   ├── explore/
│   │   ├── SKILL.md              # divergent debate orchestrator
│   │   └── block-mutating.sh     # PreToolUse hook: blocks Edit/Write/NotebookEdit/Bash
│   └── execute/
│       ├── SKILL.md              # convergent execution orchestrator
│       └── gate-mutating.sh      # PreToolUse hook: allows Edit/Write only when agent_type=imp
└── agents/
    ├── opt.md   # 🔴 Optimist (read-only)
    ├── pra.md   # 🟡 Pragmatist (read-only)
    ├── skp.md   # 🟢 Skeptic (read-only)
    ├── emp.md   # 🔵 Empiricist (read-only)
    ├── pln.md   # 📋 Planner (read-only)
    ├── imp.md   # 🔨 Implementer (Read+Edit+Write+Glob+Grep+Bash)
    └── ver.md   # ✅ Verifier (Read+Glob+Grep+Bash — no Edit)
```

Skills and agents are auto-discovered by the plugin loader from their convention directories — no explicit declaration in `plugin.json` needed.

## Install

### Recommended — install as a Claude Code plugin

This repo is both the plugin and a self-hosted single-plugin marketplace. From inside Claude Code:

```
/plugin marketplace add jwoo0122/cc-harness
/plugin install cc-harness@cc-harness
```

The first command registers the marketplace catalog (`.claude-plugin/marketplace.json`); the second installs the `cc-harness` plugin from it. Skills appear as `/cc-harness:explore` and `/cc-harness:execute`. Updates: re-run `/plugin install cc-harness@cc-harness` after the repo gets new tags.

### Local development

To test changes against an unpublished checkout:

```bash
git clone git@github.com:jwoo0122/cc-harness.git
cd cc-harness
claude --plugin-dir .
```

Then in Claude Code, `/reload-plugins` after edits. Validate the manifest with:

```bash
claude plugin validate .
```

### Fallback — manual copy (no plugin system)

If you can't use the plugin system, copy the components directly. Note the hook scripts use `${CLAUDE_PLUGIN_ROOT}` which only resolves under the plugin loader — manual copy needs the path edited to absolute or `${CLAUDE_SKILL_DIR}`.

```bash
PROJECT=/path/to/your/project
mkdir -p "$PROJECT/.claude/skills" "$PROJECT/.claude/agents"
cp -R skills/explore  "$PROJECT/.claude/skills/"
cp -R skills/execute  "$PROJECT/.claude/skills/"
cp    agents/*.md     "$PROJECT/.claude/agents/"
chmod +x "$PROJECT/.claude/skills/explore/block-mutating.sh" \
         "$PROJECT/.claude/skills/execute/gate-mutating.sh"
# After copying, edit the hook command paths in each SKILL.md from
#   ${CLAUDE_PLUGIN_ROOT}/skills/<name>/...sh
# to
#   ${CLAUDE_SKILL_DIR}/...sh
```

### Verify install

In Claude Code:

```
/cc-harness:explore "smoke test — say one sentence and stop"
```

You should see Claude entering explore mode, dispatching subagents. Try `/cc-harness:execute` similarly.

To confirm the gate works, ask in `/cc-harness:explore` mode: "edit `/tmp/x.txt`". You should see the `BLOCKED:` message from the hook.

## How the pieces fit

```
                        ┌────────────────────────────┐
                        │  /explore   (skill)        │
                        │  - divergent procedure     │
                        │  - hooks: block Edit/Write │
                        └─────────────┬──────────────┘
                                      │ Agent(subagent_type=…) ×3 in parallel
                ┌─────────────────────┼─────────────────────┐
                ▼                     ▼                     ▼
          ┌───────────┐         ┌───────────┐         ┌───────────┐
          │   opt     │         │   pra     │         │   skp     │
          │ read-only │         │ read-only │         │ read-only │
          └───────────┘         └───────────┘         └───────────┘

                        ┌────────────────────────────┐
                        │  /execute   (skill)        │
                        │  - convergent procedure    │
                        │  - hooks: gate by role     │
                        └─────────────┬──────────────┘
                                      │ Agent(subagent_type=…)
                ┌─────────────────────┼─────────────────────┐
                ▼                     ▼                     ▼
          ┌───────────┐         ┌──────────────┐      ┌───────────┐
          │   pln     │         │     imp      │      │   ver     │
          │ read-only │         │ Read+Edit+   │      │ Read+Bash │
          │           │         │ Write+Bash   │      │ (no Edit) │
          └───────────┘         └──────────────┘      └───────────┘
```

The skills are pure orchestrators — they decide what to dispatch, when, and they collect outputs. The subagents do the actual cognition in isolated contexts. The hooks enforce who-can-touch-what at the tool layer, so role discipline is structural, not vibes.

## What got dropped from the pi version (and why)

The pi extension layer adds five enforcement powers; in Claude Code these map differently:

| pi feature | Claude Code equivalent |
|------------|------------------------|
| Tool gating per mode | Skill-frontmatter `hooks:` (this package) |
| Real isolated subagents | `.claude/agents/*.md` + `Agent` tool (this package) |
| `harness_verify_register` tool | Direct `Read`+`Write` of `.harness/verification-registry.json` (IMP subagent only) |
| `harness_verify_list` tool | `Read` of the same JSON file (VER subagent) |
| `harness_commit` tool | `Bash` git commands (IMP subagent only) |
| TUI mode indicator | Not ported — Claude Code surfaces active skill in transcript |
| Cross-session AC state | **Not ported.** Each session re-derives state from `.harness/verification-registry.json` and the criteria file. |

If you need cross-session state persistence, the registry file already gives you the durable part — what's missing is per-increment progress within a session, which is fine to recompute.

## Releases

Versioning is automated via [semantic-release](https://semantic-release.gitbook.io/) on every push to `main`. Version is computed from [Conventional Commits](https://www.conventionalcommits.org/) since the last tag, then propagated to `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

| Commit prefix | Effect |
|---------------|--------|
| `feat: …` | minor bump (0.x.0) |
| `fix: …` | patch bump (0.0.x) |
| `feat!: …` or footer `BREAKING CHANGE: …` | major bump (x.0.0) |
| `chore: …`, `docs: …`, `refactor: …`, `test: …`, `ci: …` | no release |
| any commit with `[skip ci]` | workflow skipped |

The release workflow itself bumps version and creates the tag in a `chore(release): X.Y.Z [skip ci]` commit, which does not retrigger the workflow.

## License

MIT — same as the upstream pi harness.
