#!/usr/bin/env bash
# Image generation through Codex's built-in $imagegen, on your ChatGPT plan (Plus or higher).
# Usage: codex-image.sh "<what to make, size, style>" <output path>
# Exit codes: 0 saved, 2 bad usage, 3 Codex usage limit, 4 no image produced, 124 timed out.
# Hang guard: once the image exists and stops changing for DELEGATE_IMAGE_SETTLE seconds
# (default 45), Codex is stopped and the run counts as done. Some user plugins and hooks keep
# Codex alive after the work is finished.
set -uo pipefail
[[ $# -eq 2 && -n "$1" && -n "$2" ]] || { echo "usage: codex-image.sh \"<description>\" <output path>" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex not found. Install the Codex CLI and sign in with ChatGPT." >&2; exit 127; }
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"; conf_load

DESC="$1"
OUT="$2"
GEN_DIR="${CODEX_HOME:-$HOME/.codex}/generated_images"
SETTLE="${DELEGATE_IMAGE_SETTLE:-45}"
LIMIT="${DELEGATE_IMAGE_TIMEOUT:-900}"
ARGS=()
# Lean mode: skip ~/.codex/config.toml (plugins, hooks, MCP). imagegen is built in, login unaffected.
[[ "${DELEGATE_CODEX_LEAN:-$CODEX_LEAN}" == on ]] && ARGS+=(--ignore-user-config)
mkdir -p "$(dirname "$OUT")"
MARKER="$(mktemp)"
LOG="$(mktemp)"
PID=""
cleanup() { [[ -n "$PID" ]] && kill -TERM -- -"$PID" 2>/dev/null; rm -f "$MARKER" "$LOG"; }
trap cleanup EXIT

# Newest image Codex made during this run: the output path, else its own folder.
newest_image() {
  if [[ -s "$OUT" && "$OUT" -nt "$MARKER" ]]; then echo "$OUT"; return; fi
  # No xargs: with no matches, "xargs ls -t" would list the current folder instead.
  local f newest=""
  while IFS= read -r f; do
    [[ -z "$newest" || "$f" -nt "$newest" ]] && newest="$f"
  done < <(find "$GEN_DIR" -type f -newer "$MARKER" 2>/dev/null)
  echo "$newest"
}

stop_codex() {
  kill -TERM -- -"$PID" 2>/dev/null; sleep 2; kill -KILL -- -"$PID" 2>/dev/null
  wait "$PID" 2>/dev/null; PID=""
}

# Own process group (set -m) so stopping Codex also stops its hook/plugin children.
set -m
# Single quotes keep the shell from expanding $imagegen.
env -u OPENAI_API_KEY codex exec ${ARGS[@]+"${ARGS[@]}"} -s workspace-write '$imagegen '"$DESC"". Save the final file to $OUT." > "$LOG" 2>&1 &
PID=$!
set +m

start=$SECONDS last_sig="" stable_since=0 why="exited"
while kill -0 "$PID" 2>/dev/null; do
  sleep 3
  if grep -qi "usage limit" "$LOG"; then why="limit"; stop_codex; break; fi
  img="$(newest_image)"
  if [[ -n "$img" ]]; then
    sig="$img:$(wc -c < "$img" 2>/dev/null)"
    if [[ "$sig" != "$last_sig" ]]; then last_sig="$sig"; stable_since=$SECONDS
    elif (( SECONDS - stable_since >= SETTLE )); then why="settled"; stop_codex; break; fi
  fi
  if (( SECONDS - start >= LIMIT )); then why="timeout"; stop_codex; break; fi
done
[[ -n "$PID" ]] && { wait "$PID" 2>/dev/null; PID=""; }

# Show what Codex said, minus hook noise.
grep -v '^hook: ' "$LOG"

if [[ "$why" == limit ]] || grep -qi "usage limit" "$LOG"; then
  echo "[delegate] Codex is out of usage. $(grep -io 'try again at[^.]*' "$LOG" | head -1)" >&2
  exit 3
fi
[[ "$why" == settled ]] && echo "[delegate] image finished; Codex kept running, so it was stopped after ${SETTLE}s idle." >&2
img="$(newest_image)"
if [[ "$img" == "$OUT" ]]; then
  echo "[delegate] saved $OUT"; exit 0
elif [[ -n "$img" ]]; then
  cp "$img" "$OUT"; echo "[delegate] copied $img to $OUT"; exit 0
fi
[[ "$why" == timeout ]] && { echo "[delegate] timed out after ${LIMIT}s with no image" >&2; exit 124; }
echo "[delegate] no image was produced" >&2
exit 4
