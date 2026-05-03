#!/bin/bash
# install.sh — install the /chatgpt-pm-setup slash command into Claude Code
#
# Run this ONCE from the cloned chatgpt-pm-mcp directory.
# Then cd to your project and run: claude, then /chatgpt-pm-setup
#
# This copies the setup wizard into Claude Code's global commands so you can
# run /chatgpt-pm-setup from ANY project folder.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_COMMANDS="$HOME/.claude/commands"

echo "ChatGPT PM MCP — installer"
echo ""

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
echo ""
echo "Note: if you don't have a project yet, use the included demo:"
echo "  cd $REPO_DIR/demo && claude && /chatgpt-pm-setup"
