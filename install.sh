#!/usr/bin/env bash
# Installs the delegate skill for Claude Code into ~/.claude/skills/delegate.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/skills/delegate"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}/delegate"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
chmod +x "$DEST"/scripts/*.sh
echo "Installed to $DEST"
CONF="$HOME/.claude/delegate.conf"
if [[ -f "$CONF" ]]; then
  echo "Kept your settings in $CONF"
  bash "$DEST/scripts/setup.sh" --check || echo "Run setup to install what's missing: bash $DEST/scripts/setup.sh"
elif [[ -t 0 ]]; then
  bash "$DEST/scripts/setup.sh"
else
  echo "Next: bash $DEST/scripts/setup.sh   (picks your tools and installs only those)"
fi
