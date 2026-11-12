#!/usr/bin/env bash
# Image generation through Codex's built-in $imagegen, on your ChatGPT plan (Plus or higher).
# Usage: codex-image.sh "<what to make, size, style>" <output path>
# Exit codes: 0 saved, 2 bad usage, 3 Codex usage limit, 4 no image produced.
set -uo pipefail
[[ $# -eq 2 && -n "$1" && -n "$2" ]] || { echo "usage: codex-image.sh \"<description>\" <output path>" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }

DESC="$1"
OUT="$2"
GEN_DIR="${CODEX_HOME:-$HOME/.codex}/generated_images"
mkdir -p "$(dirname "$OUT")"
MARKER="$(mktemp)"
LOG="$(mktemp)"
trap 'rm -f "$MARKER" "$LOG"' EXIT

# Single quotes keep the shell from expanding $imagegen.
env -u OPENAI_API_KEY codex exec -s workspace-write '$imagegen '"$DESC"". Save the final file to $OUT." 2>&1 | tee "$LOG"

if grep -qi "usage limit" "$LOG"; then
  echo "[delegate] Codex is out of usage. $(grep -io 'try again at[^.]*' "$LOG" | head -1)" >&2
  exit 3
fi
if [[ -s "$OUT" && "$OUT" -nt "$MARKER" ]]; then
  echo "[delegate] saved $OUT"
  exit 0
fi
# Codex keeps every image in its own folder; take the newest one made during this run.
NEWEST="$(find "$GEN_DIR" -type f -newer "$MARKER" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)"
if [[ -n "$NEWEST" ]]; then
  cp "$NEWEST" "$OUT"
  echo "[delegate] copied $NEWEST to $OUT"
  exit 0
fi
echo "[delegate] no image was produced" >&2
exit 4
