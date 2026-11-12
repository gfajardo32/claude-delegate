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
else
  echo "Pick your agents: bash $DEST/scripts/menu.sh   (defaults work without it)"
fi
for tool in agy codex; do
  command -v "$tool" >/dev/null || echo "Note: $tool is not installed yet (see README)."
done
