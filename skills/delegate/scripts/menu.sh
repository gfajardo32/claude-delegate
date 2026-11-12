#!/usr/bin/env bash
# Choose which agent and model handles each kind of work.
#   menu.sh                     interactive menu (run it in your own terminal)
#   menu.sh --show              print current settings
#   menu.sh set KEY=VALUE ...   change settings without the menu (Claude uses this)
#   menu.sh --reset             back to defaults
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
conf_load

SETTINGS_JSON="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"

# Sets Claude Code's default model in settings.json (backup kept as settings.json.bak).
set_claude_default_model() {
  command -v python3 >/dev/null || { echo "python3 not found. Run /model $1 inside Claude Code instead."; return 1; }
  python3 - "$SETTINGS_JSON" "$1" <<'PY'
import json, os, shutil, sys
path, model = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)          # fails before writing if the file is not valid JSON
    shutil.copy(path, path + ".bak")
if model == "default":
    data.pop("model", None)
else:
    data["model"] = model
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("Updated " + path)
PY
}

set_one() {
  local key="${1%%=*}" val="${1#*=}" choices
  case " $CONF_KEYS " in *" $key "*) ;; *) echo "unknown setting: $key (valid: $CONF_KEYS)" >&2; return 2 ;; esac
  conf_valid_value "$val" || { echo "bad value for $key: $val" >&2; return 2; }
  choices="$(conf_choices "$key")"
  if [[ -n "$choices" ]]; then
    case " $choices " in *" $val "*) ;; *) echo "$key must be one of: $choices" >&2; return 2 ;; esac
  fi
  printf -v "$key" '%s' "$val"
  # Switching a role's agent resets its model to something that agent understands.
  case "$key" in
    LIGHT_AGENT)  LIGHT_MODEL="$(agent_default_model "$val")" ;;
    HEAVY_AGENT)  HEAVY_MODEL="$(agent_default_model "$val")" ;;
    REVIEW_AGENT) REVIEW_MODEL="$(agent_default_model "$val")" ;;
  esac
}

pick() {  # pick "<prompt>" word1 word2 ...  -> sets PICKED
  local prompt="$1"; shift
  PS3="$prompt "
  select PICKED in "$@"; do [[ -n "${PICKED:-}" ]] && break; echo "Type a number from the list."; done
}

pick_model_for() {  # pick_model_for <agent> -> sets PICKED
  # shellcheck disable=SC2046
  pick "Model for $1:" $(agent_models "$1")
  if [[ "$PICKED" == custom ]]; then
    read -r -p "Model name: " PICKED
    conf_valid_value "$PICKED" || { echo "Letters, numbers, dot, dash, underscore only."; PICKED="$(agent_default_model "$1")"; }
  fi
}

edit_role() {  # edit_role LIGHT|HEAVY|REVIEW "<label>"
  local role="$1" agent_key="${1}_AGENT" model_key="${1}_MODEL"
  # shellcheck disable=SC2046
  pick "Agent for $2:" $(conf_choices "$agent_key")
  printf -v "$agent_key" '%s' "$PICKED"
  pick_model_for "$PICKED"
  printf -v "$model_key" '%s' "$PICKED"
}

interactive() {
  [[ -t 0 ]] || { echo "The menu needs a terminal. Use: menu.sh set KEY=VALUE" >&2; exit 2; }
  echo "claude-delegate settings ($DELEGATE_CONF)"
  echo "Claude always orchestrates (that keeps every tool on its own vendor's login)."
  while true; do
    echo; conf_show; echo
    pick "Change what?" "Orchestrator model" "Light coding" "Heavy logic" "Review" "Images" "Browser" "Gemini fallback" "Reset to defaults" "Save and quit" "Quit without saving"
    case "$PICKED" in
      "Orchestrator model")
        pick "Claude model that plans and verifies:" default opus sonnet haiku
        ORCHESTRATOR_MODEL="$PICKED"
        read -r -p "Also make this Claude Code's default model in $SETTINGS_JSON? [y/N] " yn
        [[ "$yn" == [yY]* ]] && set_claude_default_model "$ORCHESTRATOR_MODEL" ;;
      "Light coding") edit_role LIGHT "light coding (edits, boilerplate, big reads)" ;;
      "Heavy logic")  edit_role HEAVY "heavy logic (hard bugs, refactors)" ;;
      "Review")       edit_role REVIEW "second-opinion reviews" ;;
      "Images")       pick "Image agent:" codex none; IMAGE_AGENT="$PICKED" ;;
      "Browser")      pick "Browser for testing web pages:" claude-chrome playwright none; BROWSER_AGENT="$PICKED" ;;
      "Gemini fallback") pick_model_for gemini; GEMINI_FALLBACK="$PICKED" ;;
      "Reset to defaults") conf_defaults ;;
      "Save and quit") conf_save; echo "Saved to $DELEGATE_CONF"; exit 0 ;;
      "Quit without saving") exit 0 ;;
    esac
  done
}

case "${1:-}" in
  "") interactive ;;
  --show) conf_show ;;
  --reset) conf_defaults; conf_save; conf_show ;;
  set)
    shift
    [[ $# -ge 1 ]] || { echo "usage: menu.sh set KEY=VALUE ..." >&2; exit 2; }
    for kv in "$@"; do set_one "$kv" || exit $?; done
    conf_save; conf_show ;;
  *) echo "usage: menu.sh [--show | --reset | set KEY=VALUE ...]" >&2; exit 2 ;;
esac
