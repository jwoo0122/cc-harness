#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
cd "$ROOT"

SAMPLE=".iteration-7"
CREATED=0
if [[ ! -d "$SAMPLE" ]]; then
  mkdir -p "$SAMPLE"
  echo "stub" > "$SAMPLE/brief.md"
  CREATED=1
fi

trap '[[ "$CREATED" -eq 1 ]] && rm -rf "$ROOT/$SAMPLE"' EXIT

if ! git check-ignore -q "$SAMPLE/brief.md"; then
  fail "git does NOT ignore $SAMPLE/brief.md — .gitignore rule missing or wrong"
fi
ok "git ignores $SAMPLE/brief.md"

SOURCE="$(git check-ignore -v "$SAMPLE/brief.md" | awk '{print $1}')"
case "$SOURCE" in
  *.gitignore*) ok "ignore rule sourced from repo .gitignore ($SOURCE)" ;;
  *) fail "ignore rule sourced from unexpected location: $SOURCE" ;;
esac

pass "ac-1.3 edge PASS"
