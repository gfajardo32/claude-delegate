#!/usr/bin/env bash
# Read-only second opinion / code review through the Codex CLI.
# Usage: codex-review.sh "<what to review and what to look for>"
# Model: DELEGATE_CODEX_MODEL (unset or "default" = Codex's own default).
set -uo pipefail
[[ $# -ge 1 && -n "$1" ]] || { echo "usage: codex-review.sh \"<what to review>\"" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }
MODEL_ARGS=()
[[ -n "${DELEGATE_CODEX_MODEL:-}" && "${DELEGATE_CODEX_MODEL}" != default ]] && MODEL_ARGS=(-m "$DELEGATE_CODEX_MODEL")
exec env -u OPENAI_API_KEY codex exec ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} -s read-only "$1

Do not edit anything. Reply with a short list of concrete problems (file, line, why)."
