# Shared config helpers for the delegate skill. Sourced, not run.
# Config lives outside the skill folder so reinstalling never wipes it.
# Written for bash 3.2 (the macOS default): no associative arrays.

DELEGATE_CONF="${DELEGATE_CONF:-$HOME/.claude/delegate.conf}"

CONF_KEYS="ORCHESTRATOR_MODEL LIGHT_AGENT LIGHT_MODEL HEAVY_AGENT HEAVY_MODEL REVIEW_AGENT REVIEW_MODEL IMAGE_AGENT BROWSER_AGENT GEMINI_FALLBACK CODEX_LEAN"

conf_defaults() {
  ORCHESTRATOR_MODEL=default
  LIGHT_AGENT=gemini;  LIGHT_MODEL=gemini-4-hydrogen-medium
  HEAVY_AGENT=codex;   HEAVY_MODEL=default
  REVIEW_AGENT=codex;  REVIEW_MODEL=default
  IMAGE_AGENT=codex
  BROWSER_AGENT=claude-chrome
  GEMINI_FALLBACK=gemini-3.8-flash-medium
  CODEX_LEAN=on
}

# Allowed choices per setting. Models are free text (validated by charset only).
conf_choices() {
  case "$1" in
    ORCHESTRATOR_MODEL) echo "default opus sonnet haiku" ;;
    LIGHT_AGENT|HEAVY_AGENT|REVIEW_AGENT) echo "gemini codex claude" ;;
    IMAGE_AGENT)   echo "codex none" ;;
    BROWSER_AGENT) echo "claude-chrome playwright none" ;;
    CODEX_LEAN)    echo "on off" ;;
    *) echo "" ;;
  esac
}

conf_valid_value() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]; }

# Parses the file instead of sourcing it, so a bad line can't run code.
conf_load() {
  conf_defaults
  [[ -f "$DELEGATE_CONF" ]] || return 0
  local k v
  while IFS='=' read -r k v || [[ -n "$k" ]]; do
    k="$(printf '%s' "$k" | tr -d " \t\r")"
    [[ -z "$k" || "$k" == \#* ]] && continue
    case " $CONF_KEYS " in *" $k "*) ;; *) continue ;; esac
    v="${v%%#*}"
    v="$(printf '%s' "$v" | tr -d " \t\r\"'")"
    conf_valid_value "$v" && printf -v "$k" '%s' "$v"
  done < "$DELEGATE_CONF"
}

conf_save() {
  mkdir -p "$(dirname "$DELEGATE_CONF")"
  local tmp="$DELEGATE_CONF.tmp.$$" k
  {
    echo "# claude-delegate settings. Edit with: bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/menu.sh"
    for k in $CONF_KEYS; do echo "$k=${!k}"; done
  } > "$tmp" && mv "$tmp" "$DELEGATE_CONF"
}

conf_show() {
  echo "Orchestrator (Claude)  : $ORCHESTRATOR_MODEL"
  echo "Light coding           : $LIGHT_AGENT ($(model_label "$LIGHT_AGENT" "$LIGHT_MODEL"))"
  echo "Heavy logic            : $HEAVY_AGENT ($(model_label "$HEAVY_AGENT" "$HEAVY_MODEL"))"
  echo "Review                 : $REVIEW_AGENT ($(model_label "$REVIEW_AGENT" "$REVIEW_MODEL"))"
  echo "Images                 : $IMAGE_AGENT"
  echo "Browser                : $BROWSER_AGENT"
  echo "Gemini fallback        : $GEMINI_FALLBACK"
  echo "Codex lean mode        : $CODEX_LEAN (skip your Codex plugins, hooks and MCP for delegated runs)"
}

model_label() { [[ "$2" == default ]] && echo "$1 default model" || echo "$2"; }

# Model presets offered in the menu for each agent ("custom" lets you type one).
agent_models() {
  case "$1" in
    gemini) echo "gemini-4-hydrogen-medium gemini-3.8-flash-medium custom" ;;
    codex)  echo "default custom" ;;
    claude) echo "haiku sonnet opus" ;;
    *)      echo "default" ;;
  esac
}

# Sensible model when switching a role to a new agent.
agent_default_model() {
  case "$1" in
    gemini) echo "gemini-4-hydrogen-medium" ;;
    claude) echo "sonnet" ;;
    *)      echo "default" ;;
  esac
}

# ---- Tool requirements (used by setup.sh) ----
# Prints one tool id per line for what the current config needs: agy codex playwright chrome
needed_tools() {
  local roles="$LIGHT_AGENT $HEAVY_AGENT $REVIEW_AGENT"
  case " $roles " in *" gemini "*) echo agy ;; esac
  case " $roles $IMAGE_AGENT " in *" codex "*) echo codex ;; esac
  [[ "$BROWSER_AGENT" == playwright ]] && echo playwright
  [[ "$BROWSER_AGENT" == claude-chrome ]] && echo chrome
  return 0
}

tool_installed() {
  case "$1" in
    agy)   command -v agy >/dev/null ;;
    codex) command -v codex >/dev/null ;;
    playwright) command -v claude >/dev/null && claude mcp list 2>/dev/null | grep -qi playwright ;;
    chrome) return 0 ;;  # browser extension, can't be checked from a shell
  esac
}

tool_install_cmd() {
  case "$1" in
    agy)   echo "curl -fsSL https://antigravity.google/cli/install.sh | bash" ;;
    codex) echo "npm install -g @openai/codex" ;;
    playwright) echo "claude mcp add playwright -- npx @playwright/mcp@latest" ;;
  esac
}

tool_about() {
  case "$1" in
    agy)   echo "Antigravity CLI (Gemini). Free with a Google account. Sign in on first run: agy" ;;
    codex) echo "OpenAI Codex CLI. Needs ChatGPT (Plus or higher for images). Sign in after install: codex login" ;;
    playwright) echo "Playwright MCP server, lets Claude drive a headless browser. Needs Node (npx)." ;;
    chrome) echo "Claude in Chrome extension. Install it from the Chrome Web Store, then start Claude Code with: claude --chrome" ;;
  esac
}
