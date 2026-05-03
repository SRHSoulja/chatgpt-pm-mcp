#!/bin/bash
# watcher.sh — watches .mcp-prompts/ for new tasks from ChatGPT
# Run this in a Claude Code session: bash watcher.sh
#
# When ChatGPT calls submit_prompt(), a .md file lands in .mcp-prompts/.
# This script detects it and prints the content so Claude Code can act on it.
# Claude should write its response to .mcp-response.md when done.

PROMPT_DIR="${PROJECT_ROOT:-.}/.mcp-prompts"
mkdir -p "$PROMPT_DIR"

echo "Watching $PROMPT_DIR for new prompts from ChatGPT..."
echo "When a prompt arrives, read it, execute the task, then write your summary to .mcp-response.md"
echo "---"

if command -v inotifywait &>/dev/null; then
  # Linux/WSL: inotify-based (instant)
  inotifywait -m -e create "$PROMPT_DIR" --format '%f' 2>/dev/null | while read -r f; do
    echo ""
    echo "=== New prompt from ChatGPT: $f ==="
    cat "$PROMPT_DIR/$f"
    echo ""
    echo "=== Execute the above task, then write your response to .mcp-response.md ==="
  done
elif command -v fswatch &>/dev/null; then
  # Mac: fswatch-based
  fswatch -0 "$PROMPT_DIR" | xargs -0 -I{} sh -c '
    f="{}"
    if [[ "$f" == *.md ]]; then
      echo ""
      echo "=== New prompt from ChatGPT: $(basename $f) ==="
      cat "$f"
      echo ""
      echo "=== Execute the above task, then write your response to .mcp-response.md ==="
    fi
  '
else
  # Fallback: polling every 3 seconds
  LAST=""
  while true; do
    LATEST=$(ls -t "$PROMPT_DIR"/*.md 2>/dev/null | head -1)
    if [[ -n "$LATEST" && "$LATEST" != "$LAST" ]]; then
      LAST="$LATEST"
      echo ""
      echo "=== New prompt from ChatGPT: $(basename $LATEST) ==="
      cat "$LATEST"
      echo ""
      echo "=== Execute the above task, then write your response to .mcp-response.md ==="
    fi
    sleep 3
  done
fi
