#!/usr/bin/env bash
# First-run setup: asks which tools you want, sets roles to match, then installs only those.
#   setup.sh           interactive (run it in your own terminal)
#   setup.sh --check   list missing tools for the current settings (exit 6 if any)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
conf_load

check() {
  local t missing=0
  for t in $(needed_tools); do
    if [[ "$t" == chrome ]]; then
      echo "MANUAL chrome: $(tool_about chrome)"
    elif tool_installed "$t"; then
      echo "OK $t"
    else
      echo "MISSING $t: $(tool_about "$t")"
      echo "  install: $(tool_install_cmd "$t")"
      missing=1
    fi
  done
  [[ $missing -eq 0 ]] || return 6
}

yes_no() {  # yes_no "<question>" <default y|n>
  local a; read -r -p "$1 " a
  [[ -z "$a" ]] && a="$2"
  [[ "$a" == [yY]* ]]
}

if [[ "${1:-}" == "--check" ]]; then check; exit $?; fi
[[ -t 0 ]] || { echo "setup.sh needs a terminal. For a check only: setup.sh --check" >&2; exit 2; }

echo "claude-delegate setup"
echo "Claude always plans and checks the work. Pick which other tools do the typing."
echo "Anything you skip is handled by a Claude subagent instead (uses your Claude plan)."
echo
yes_no "Use Gemini through the Antigravity CLI (free, Google login)? [Y/n]" y && USE_G=1 || USE_G=0
yes_no "Use OpenAI Codex CLI (ChatGPT login, also makes images)? [Y/n]" y && USE_C=1 || USE_C=0
PS3="Browser for checking web pages: "
select BROWSER_AGENT in claude-chrome playwright none; do [[ -n "${BROWSER_AGENT:-}" ]] && break; done

# Sensible roles from the answers. Fine-tune any of them in menu.sh.
if   [[ $USE_G == 1 && $USE_C == 1 ]]; then L=gemini:gemini-4-hydrogen-medium H=codex:default R=codex:default IMAGE_AGENT=codex
elif [[ $USE_G == 1 ]];                then L=gemini:gemini-4-hydrogen-medium H=claude:opus  R=claude:sonnet  IMAGE_AGENT=none
elif [[ $USE_C == 1 ]];                then L=codex:default H=codex:default R=codex:default IMAGE_AGENT=codex
else                                        L=claude:haiku H=claude:opus R=claude:sonnet IMAGE_AGENT=none
fi
LIGHT_AGENT="${L%%:*}";  LIGHT_MODEL="${L#*:}"
HEAVY_AGENT="${H%%:*}";  HEAVY_MODEL="${H#*:}"
REVIEW_AGENT="${R%%:*}"; REVIEW_MODEL="${R#*:}"
conf_save
echo; conf_show; echo
yes_no "Change any role in the full menu? [y/N]" n && { bash "$HERE/menu.sh"; conf_load; }

echo; echo "Checking tools for these settings..."
for t in $(needed_tools); do
  if [[ "$t" == chrome ]]; then echo "- $(tool_about chrome)"; continue; fi
  if tool_installed "$t"; then echo "- $t: installed"; continue; fi
  echo "- $t is missing. $(tool_about "$t")"
  cmd="$(tool_install_cmd "$t")"
  [[ "$t" == codex ]] && ! command -v npm >/dev/null && { echo "  npm not found. Install Node.js first (https://nodejs.org), then: $cmd"; continue; }
  [[ "$t" == playwright ]] && ! command -v claude >/dev/null && { echo "  claude not found on PATH. Later run: $cmd"; continue; }
  echo "  Command: $cmd"
  if yes_no "  Run it now? [y/N]" n; then
    bash -c "$cmd" && echo "  Installed $t." || echo "  Install failed. Run it yourself: $cmd"
  else
    echo "  Skipped. Run it later: $cmd"
  fi
done
echo
echo "Sign in once to each tool you installed (agy: run agy. codex: run codex login)."
echo "Change choices any time: bash $HERE/menu.sh"
