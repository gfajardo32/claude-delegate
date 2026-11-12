#!/usr/bin/env bash
# Hard coding tasks through the OpenAI Codex CLI, on your ChatGPT login.
# Edits stay inside the current folder (workspace-write sandbox).
# Usage: codex-task.sh "<instructions>"
set -uo pipefail
[[ $# -ge 1 && -n "$1" ]] || { echo "usage: codex-task.sh \"<instructions>\"" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }
# Never bill an API key: without OPENAI_API_KEY, Codex uses the ChatGPT plan.
exec env -u OPENAI_API_KEY codex exec -s workspace-write "$1

Reply with a short summary of what you changed. Do not paste whole files."
