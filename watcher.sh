#!/bin/bash
# watcher.sh — watches .mcp-prompts/ for new tasks from ChatGPT
#
# When ChatGPT calls submit_prompt(), a .md file lands in .mcp-prompts/.
# This script detects new files and writes their paths to .mcp-events.log
# so Claude Code can Monitor that log and auto-execute each task.

PROMPT_DIR="${PROJECT_ROOT:-.}/.mcp-prompts"
EVENTS_LOG="${PROJECT_ROOT:-.}/.mcp-events.log"

mkdir -p "$PROMPT_DIR"
touch "$EVENTS_LOG"

echo "Watching $PROMPT_DIR for new prompts from ChatGPT..."
echo "Events log: $EVENTS_LOG"
echo "---"

emit() {
  local filepath="$1"
  echo "$filepath" >> "$EVENTS_LOG"
  echo "[watcher] prompt arrived: $(basename "$filepath")"
}

if command -v inotifywait &>/dev/null; then
  # Linux/WSL: inotify-based (instant)
  inotifywait -m -e create "$PROMPT_DIR" --format '%f' 2>/dev/null | while read -r f; do
    [[ "$f" == *.md ]] && emit "$PROMPT_DIR/$f"
  done
elif command -v fswatch &>/dev/null; then
  # Mac: fswatch-based
  fswatch "$PROMPT_DIR" | while read -r f; do
    [[ "$f" == *.md ]] && emit "$f"
  done
else
  # Fallback: polling every 3 seconds
  LAST=""
  while true; do
    LATEST=$(ls -t "$PROMPT_DIR"/*.md 2>/dev/null | head -1)
    if [[ -n "$LATEST" && "$LATEST" != "$LAST" ]]; then
      LAST="$LATEST"
      emit "$LATEST"
    fi
    sleep 3
  done
fi
