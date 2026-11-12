#!/usr/bin/env bash
# Coding tasks through the OpenAI Codex CLI, on your ChatGPT login.
# Edits stay inside the current folder (workspace-write sandbox).
# Usage: codex-task.sh [--read-only] "<instructions>"
# Model: DELEGATE_CODEX_MODEL (unset or "default" = whatever ~/.codex/config.toml uses).
# Exit codes: 0 done, 2 bad usage, 3 Codex usage limit (prints the reset time), 127 not installed.
set -uo pipefail
SANDBOX="workspace-write"
TAIL="Reply with a short summary of what you changed. Do not paste whole files."
if [[ "${1:-}" == "--read-only" ]]; then SANDBOX="read-only"; TAIL="Do not edit anything. Answer briefly."; shift; fi
[[ $# -ge 1 && -n "$1" ]] || { echo "usage: codex-task.sh [--read-only] \"<instructions>\"" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }
MODEL_ARGS=()
[[ -n "${DELEGATE_CODEX_MODEL:-}" && "${DELEGATE_CODEX_MODEL}" != default ]] && MODEL_ARGS=(-m "$DELEGATE_CODEX_MODEL")
LOG="$(mktemp)"; trap 'rm -f "$LOG"' EXIT
# Never bill an API key: without OPENAI_API_KEY, Codex uses the ChatGPT plan.
env -u OPENAI_API_KEY codex exec ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} -s "$SANDBOX" "$1

$TAIL" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
if grep -qi "usage limit" "$LOG"; then
  echo "[delegate] Codex is out of usage. $(grep -io 'try again at[^.]*' "$LOG" | head -1)" >&2
  exit 3
fi
exit "$rc"
