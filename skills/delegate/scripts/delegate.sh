#!/usr/bin/env bash
# Routes a task to whichever agent the user picked for that role (see menu.sh).
# Usage:
#   delegate.sh light  "<instructions>"     routine coding, edits, boilerplate
#   delegate.sh heavy  "<instructions>"     hard bugs, tricky refactors
#   delegate.sh read   "<question>"         big codebase read, no edits (light agent)
#   delegate.sh review "<what to review>"   read-only second opinion
#   delegate.sh image  "<description>" <output path>
#   delegate.sh browser                     prints which browser to use
# Exit 10 = this role is set to Claude: do it with a subagent (the line printed
# says which model). Exit 5 = this role is turned off.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
conf_load

role="${1:-}"; shift || true

claude_subagent() {  # claude_subagent <role> <model>
  echo "CLAUDE_SUBAGENT role=$1 model=$2"
  echo "[delegate] $1 is set to Claude. Run it as a subagent (Task tool) with model \"$2\"." >&2
  exit 10
}

run_coder() {  # run_coder <agent> <model> <role> [--read-only] "<prompt>"
  local agent="$1" model="$2" r="$3"; shift 3
  case "$agent" in
    gemini) DELEGATE_GEMINI_MODEL="$model" DELEGATE_GEMINI_FALLBACK="$GEMINI_FALLBACK" exec bash "$HERE/gemini-task.sh" "$@" ;;
    codex)  DELEGATE_CODEX_MODEL="$model" exec bash "$HERE/codex-task.sh" "$@" ;;
    claude) claude_subagent "$r" "$model" ;;
    *) echo "[delegate] unknown agent '$agent' for $r. Fix it with menu.sh." >&2; exit 2 ;;
  esac
}

case "$role" in
  light)  run_coder "$LIGHT_AGENT" "$LIGHT_MODEL" light "$@" ;;
  heavy)  run_coder "$HEAVY_AGENT" "$HEAVY_MODEL" heavy "$@" ;;
  read)   run_coder "$LIGHT_AGENT" "$LIGHT_MODEL" read --read-only "$@" ;;
  review)
    case "$REVIEW_AGENT" in
      codex)  DELEGATE_CODEX_MODEL="$REVIEW_MODEL" exec bash "$HERE/codex-review.sh" "$@" ;;
      gemini) DELEGATE_GEMINI_MODEL="$REVIEW_MODEL" DELEGATE_GEMINI_FALLBACK="$GEMINI_FALLBACK" exec bash "$HERE/gemini-task.sh" --read-only "$@" ;;
      claude) claude_subagent review "$REVIEW_MODEL" ;;
      *) echo "[delegate] unknown review agent '$REVIEW_AGENT'" >&2; exit 2 ;;
    esac ;;
  image)
    case "$IMAGE_AGENT" in
      codex) exec bash "$HERE/codex-image.sh" "$@" ;;
      none)  echo "[delegate] image generation is turned off (menu.sh). Ask the user for the image." >&2; exit 5 ;;
      *) echo "[delegate] unknown image agent '$IMAGE_AGENT'" >&2; exit 2 ;;
    esac ;;
  browser)
    echo "BROWSER=$BROWSER_AGENT"
    [[ "$BROWSER_AGENT" == none ]] && exit 5
    exit 0 ;;
  --show|config) conf_show ;;
  *) sed -n '2,12p' "$0" >&2; exit 2 ;;
esac
