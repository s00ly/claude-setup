#!/bin/bash
# ──────────────────────────────────────────────────────────
# Claude Code Project Setup — s00ly
# Installs global slash commands for all projects.
# Works on Linux, macOS, and Windows (Git Bash / MSYS2).
# ──────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"
COMMANDS_DST="$HOME/.claude/commands"

# Create target directory
mkdir -p "$COMMANDS_DST"

echo ""
echo "  Claude Code — Project Setup"
echo "  ──────────────────────────────"
echo ""

# Detect OS for symlink vs copy
is_windows() {
  [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin"* ]]
}

installed=()

for cmd in "$COMMANDS_SRC"/*.md; do
  [ -f "$cmd" ] || continue
  name=$(basename "$cmd")
  cmd_name=$(basename "$name" .md)

  # Remove existing (symlink or file)
  rm -f "$COMMANDS_DST/$name"

  if is_windows; then
    cp "$cmd" "$COMMANDS_DST/$name"
  else
    ln -sf "$cmd" "$COMMANDS_DST/$name"
  fi

  installed+=("/$cmd_name")
  echo "  ✓ /$cmd_name"
done

echo ""
if is_windows; then
  echo "  Mode: copy (Windows)"
  echo "  To update commands later: pull this repo and re-run install.sh"
else
  echo "  Mode: symlink (Unix)"
  echo "  Commands auto-update when you pull this repo."
fi

echo ""
echo "  Installed ${#installed[@]} command(s): ${installed[*]}"
echo ""
echo "  Open Claude Code and type any command to start."
echo ""
