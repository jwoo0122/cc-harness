#!/bin/bash
# Codex CLI wrapper — stdin-only prompt, preflight auth + loud-fail,
# configurable timeout (default 60s), injection-safe (no prompt on ARGV),
# JSON Lines stdout.
#
# Usage:
#   echo "prompt" | call-codex.sh
#   HARNESS_CODEX_TIMEOUT=30 echo "prompt" | call-codex.sh
#
# Env:
#   HARNESS_CODEX_TIMEOUT — seconds (default 60, must be a positive integer)
#   OPENAI_API_KEY        — required (preflight)
#
# Exit codes:
#   0   — success
#   2   — preflight failure (missing binary / missing/invalid API key,
#         invalid HARNESS_CODEX_TIMEOUT) + stderr warning with exact prefix
#   3   — timeout + stderr warning
#   !=0 (not 2, not 3) — runtime/codex failure (quota, network, parse, etc.)
#
# Security:
#   - Prompts are read from stdin ONLY. Any positional ARGV is ignored.
#   - The prompt is never expanded by the shell. `codex exec --json` is
#     invoked with a fixed, literal argv list; the prompt flows as bytes
#     through stdin.
#   - The shebang uses an absolute path so the script still executes under
#     hostile PATH values (e.g. PATH=/nonexistent:/tmp) and can emit the
#     preflight warning rather than dying at exec time.
#
# Uses absolute shebang `/bin/bash` (present on macOS and all mainstream
# Linux distros) because `/usr/bin/env bash` fails under stripped PATH.

set -euo pipefail

# --- helpers ---------------------------------------------------------------

preflight_fail() {
  local reason="$1"
  echo "⚠ Codex preflight failed: $reason" >&2
  exit 2
}

# --- timeout parsing (default 60) -----------------------------------------
# Must be a positive integer. 0 and negative values are rejected loudly
# (AC-B.3 adversarial forbids silently disabling the budget).
DEFAULT_TIMEOUT=60
TIMEOUT="${HARNESS_CODEX_TIMEOUT:-$DEFAULT_TIMEOUT}"
case "$TIMEOUT" in
  ''|-*|*[!0-9-]*)
    echo "⚠ HARNESS_CODEX_TIMEOUT invalid: must be a positive integer (got '$TIMEOUT')" >&2
    exit 2
    ;;
esac
# Reject 0 and (redundantly) anything non-positive.
if [ "$TIMEOUT" -le 0 ]; then
  echo "⚠ HARNESS_CODEX_TIMEOUT invalid: must be >= 1 (got '$TIMEOUT')" >&2
  exit 2
fi

# --- preflight -------------------------------------------------------------

# codex binary must be on PATH
command -v codex >/dev/null 2>&1 \
  || preflight_fail "codex binary not found on PATH (install Codex CLI or fix PATH)"

# OPENAI_API_KEY must be set and look plausible.
if [ -z "${OPENAI_API_KEY:-}" ]; then
  preflight_fail "OPENAI_API_KEY env var is not set"
fi

case "$OPENAI_API_KEY" in
  sk-*|sk_*)
    # Accept sk- / sk_ prefixed tokens (OpenAI convention). Real validation
    # happens server-side; we only reject obvious absence/placeholders here.
    ;;
  *)
    # Non-sk tokens (e.g. custom orgs) must at least be plausibly long.
    # AC-B.2 edge rejects "not-a-real-key" (14 chars).
    if [ "${#OPENAI_API_KEY}" -lt 40 ]; then
      preflight_fail "OPENAI_API_KEY looks invalid (unexpected shape)"
    fi
    ;;
esac

# --- buffer stdin → tempfile ----------------------------------------------
# We buffer stdin to a temp file so we can run codex as a child with its
# stdin explicitly redirected from that file. This avoids the standard bash
# footgun where backgrounded commands inherit /dev/null for stdin (which
# would silently break stdin forwarding in the no-`timeout` fallback path).
# Bytes flow through unchanged — no `read`, no quoting, no escape.

STDIN_BUFFER="$(mktemp -t call-codex-stdin.XXXXXX)"
trap 'rm -f "$STDIN_BUFFER"' EXIT
cat >"$STDIN_BUFFER"

# --- run codex -------------------------------------------------------------
# Injection-safe: `codex exec --json` is a literal argv list. The user prompt
# is on stdin only and is never subject to shell expansion.

has_timeout_cmd() {
  command -v timeout >/dev/null 2>&1
}

emit_timeout_warning() {
  echo "⚠ Codex exceeded HARNESS_CODEX_TIMEOUT=${TIMEOUT}s (timed out)" >&2
}

if has_timeout_cmd; then
  # GNU coreutils `timeout`: returns 124 on timeout, 137 if SIGKILL followed.
  set +e
  timeout "$TIMEOUT" codex exec --json <"$STDIN_BUFFER"
  rc=$?
  set -e
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    emit_timeout_warning
    exit 3
  fi
  exit "$rc"
else
  # Portable fallback: use perl's SIGALRM to bound codex runtime. This keeps
  # stdin/stdout/stderr attached to the current process (unlike a `cmd &`
  # background job, which would detach stdin to /dev/null in non-interactive
  # bash). Perl is guaranteed present on macOS and nearly all Linux distros.
  set +e
  perl -e '
    my $t = shift @ARGV;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
      exec { $ARGV[0] } @ARGV or die "exec: $!";
    }
    local $SIG{ALRM} = sub { kill "TERM", $pid; sleep 1; kill "KILL", $pid; exit 124; };
    alarm $t;
    waitpid($pid, 0);
    alarm 0;
    my $status = $?;
    if ($status & 127) { exit 128 + ($status & 127); }
    exit ($status >> 8);
  ' "$TIMEOUT" codex exec --json <"$STDIN_BUFFER"
  rc=$?
  set -e
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ] || [ "$rc" -eq 143 ]; then
    emit_timeout_warning
    exit 3
  fi
  exit "$rc"
fi
