#!/bin/bash
# install.sh — install the /chatgpt-pm-setup slash command into Claude Code
#
# Run this ONCE from the cloned chatgpt-pm-mcp directory.
# Then cd to your project and run: claude, then /chatgpt-pm-setup
#
# Supported: Linux, macOS, Windows via WSL2
# NOT supported: native Windows PowerShell or CMD

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_COMMANDS="$HOME/.claude/commands"
CONFIG_DIR="$HOME/.chatgpt-pm-mcp"
REPO_PATH_FILE="$CONFIG_DIR/repo-path"

echo "ChatGPT PM MCP — installer"
echo "Supported environments: Linux, macOS, Windows via WSL2"
echo ""

# Save the actual repo path so the setup wizard can find it later
mkdir -p "$CONFIG_DIR"
echo "$REPO_DIR" > "$REPO_PATH_FILE"
echo "✓ Saved repo path to $REPO_PATH_FILE"
echo "  (Setup wizard will use this to find the MCP server files)"

# Create global Claude commands dir if needed
mkdir -p "$CLAUDE_COMMANDS"

# Copy the setup command
cp "$REPO_DIR/.claude/commands/chatgpt-pm-setup.md" "$CLAUDE_COMMANDS/chatgpt-pm-setup.md"
echo "✓ Installed /chatgpt-pm-setup to $CLAUDE_COMMANDS"

# Copy the session command
cp "$REPO_DIR/.claude/commands/chatgpt-session.md" "$CLAUDE_COMMANDS/chatgpt-session.md"
echo "✓ Installed /chatgpt-session to $CLAUDE_COMMANDS"

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. cd /path/to/your/project    (or: cd $REPO_DIR/demo)"
echo "  2. claude"
echo "  3. /chatgpt-pm-setup"
echo ""
echo "The setup wizard will walk you through everything from there."
echo "It knows the repo is at: $REPO_DIR"
