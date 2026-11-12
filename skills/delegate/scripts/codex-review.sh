#!/usr/bin/env bash
# Read-only second opinion / code review through the Codex CLI.
# Usage: codex-review.sh "<what to review and what to look for>"
set -uo pipefail
[[ $# -ge 1 && -n "$1" ]] || { echo "usage: codex-review.sh \"<what to review>\"" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }
exec env -u OPENAI_API_KEY codex exec -s read-only "$1

Do not edit anything. Reply with a short list of concrete problems (file, line, why)."
