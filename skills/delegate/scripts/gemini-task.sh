#!/usr/bin/env bash
# Routine coding through Gemini in the Antigravity CLI (agy), on your Google login.
# Usage: gemini-task.sh [--read-only] "<instructions>"
# Exit codes: 0 done, 2 bad usage, 7 agy can't write here (folder not trusted / permission
# denied), 127 agy not installed, other = agy failed on both models.
set -uo pipefail
# Model order: env var, then ~/.claude/delegate.conf (menu.sh), then built-in default.
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
conf_load
MODEL="${DELEGATE_GEMINI_MODEL:-$LIGHT_MODEL}"
FALLBACK="${DELEGATE_GEMINI_FALLBACK:-$GEMINI_FALLBACK}"
# A non-Gemini model in the config (light coding set to another agent) means use the default.
[[ "$MODEL" == gemini-* ]] || MODEL="gemini-4-hydrogen-medium"
TIMEOUT="${DELEGATE_TIMEOUT:-600s}"
MODE="accept-edits"
AGY_SETTINGS="${DELEGATE_AGY_SETTINGS:-$HOME/.gemini/antigravity-cli/settings.json}"

if [[ "${1:-}" == "--read-only" ]]; then MODE="plan"; shift; fi
if [[ $# -lt 1 || -z "$1" ]]; then
  echo "usage: gemini-task.sh [--read-only] \"<instructions>\"" >&2
  exit 2
fi
command -v agy >/dev/null || { echo "agy not found. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash" >&2; exit 127; }

untrusted_msg() {
  echo "[delegate] agy can't write files in $(pwd -P): it only edits inside its trusted folders." >&2
  echo "[delegate] Fix: add this folder (or a parent) to \"trustedWorkspaces\" in $AGY_SETTINGS, then rerun." >&2
}

# Pre-check, edits only: is the real path of this folder inside a trusted workspace?
# Skipped (not fatal) if python3 or the settings file is missing; the output check below still applies.
if [[ "$MODE" == accept-edits && -f "$AGY_SETTINGS" ]] && command -v python3 >/dev/null; then
  python3 - "$AGY_SETTINGS" "$(pwd -P)" <<'PY'
import json, os, sys
path, cwd = sys.argv[1], sys.argv[2]
try:
    roots = json.load(open(path)).get("trustedWorkspaces", [])
except Exception:
    sys.exit(0)  # unreadable settings: don't block, let agy decide
for r in roots:
    r = os.path.realpath(os.path.expanduser(r)).rstrip("/")
    if cwd == r or cwd.startswith(r + "/"):
        sys.exit(0)
sys.exit(7)
PY
  [[ $? -eq 7 ]] && { untrusted_msg; exit 7; }
fi

PROMPT="$1

Do NOT run any shell commands. Only create and edit files.
Reply with a short summary of what you changed. Do not paste whole files."
[[ "$MODE" == "plan" ]] && PROMPT="$1

Do NOT edit files or run shell commands. Answer briefly."

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# agy exits 0 even when headless mode auto-denies a tool, so check its output too.
run() {
  agy --model "$1" --mode "$MODE" --sandbox --print-timeout "$TIMEOUT" -p "$PROMPT" 2>&1 | tee "$LOG"
  local rc=${PIPESTATUS[0]}
  if grep -qiE "auto-denied|no output produced|cannot prompt for" "$LOG"; then return 7; fi
  return "$rc"
}

run "$MODEL"; rc=$?
[[ $rc -eq 0 ]] && exit 0
[[ $rc -eq 7 ]] && { untrusted_msg; exit 7; }
echo "[delegate] $MODEL failed, retrying once with $FALLBACK" >&2
run "$FALLBACK"; rc=$?
[[ $rc -eq 7 ]] && untrusted_msg
exit "$rc"
