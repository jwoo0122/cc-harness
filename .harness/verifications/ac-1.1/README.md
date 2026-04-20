# AC-1.1 verification bundle

Proves: `docs/iteration-layout.md` exists and documents the exact required file set
(`brief.md`, `verify-report.md`, `decision-log.md`) plus the directory-name regex.

## Scripts
- `happy.sh` — three required filenames present; doc asserts they are required.
- `edge.sh` — exact regex literal present; no forbidden alt-filename bullets; no legacy
  `target/explore/*.md` sink references.

## Run
```sh
bash happy.sh
bash edge.sh
```

## Pre-implementation expectation
Both scripts FAIL — `docs/iteration-layout.md` does not yet exist.
