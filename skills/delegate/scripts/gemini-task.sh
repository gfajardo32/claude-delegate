#!/usr/bin/env bash
# Routine coding through Gemini in the Antigravity CLI (agy), on your Google login.
# Usage: gemini-task.sh [--read-only] "<instructions>"
set -uo pipefail

MODEL="${DELEGATE_GEMINI_MODEL:-gemini-4-hydrogen-medium}"
FALLBACK="${DELEGATE_GEMINI_FALLBACK:-gemini-3.8-flash-medium}"
TIMEOUT="${DELEGATE_TIMEOUT:-600s}"
MODE="accept-edits"

if [[ "${1:-}" == "--read-only" ]]; then MODE="plan"; shift; fi
if [[ $# -lt 1 || -z "$1" ]]; then
  echo "usage: gemini-task.sh [--read-only] \"<instructions>\"" >&2
  exit 2
fi
command -v agy >/dev/null || { echo "agy not found. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash" >&2; exit 127; }

PROMPT="$1

Do NOT run any shell commands. Only create and edit files.
Reply with a short summary of what you changed. Do not paste whole files."
[[ "$MODE" == "plan" ]] && PROMPT="$1

Do NOT edit files or run shell commands. Answer briefly."

run() { agy --model "$1" --mode "$MODE" --sandbox --print-timeout "$TIMEOUT" -p "$PROMPT"; }

if run "$MODEL"; then exit 0; fi
echo "[delegate] $MODEL failed, retrying once with $FALLBACK" >&2
run "$FALLBACK"
