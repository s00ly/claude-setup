#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Claude Code Plugin Sync
# Ensures all stations have identical plugin stack.
# Run via install.sh or standalone: bash sync-plugins.sh
# Updated: 2026-04-08
# ──────────────────────────────────────────────────────────
set -e

echo ""
echo "  Claude Code — Plugin Sync"
echo "  ──────────────────────────────"
echo ""

# 1. Marketplace
echo "  [1/4] Updating marketplace..."
claude plugin marketplace update 2>/dev/null || true

# 2. Install (idempotent)
PLUGINS=(
  agent-sdk-dev
  claude-code-setup
  claude-md-management
  code-simplifier
  commit-commands
  context7
  explanatory-output-style
  feature-dev
  firecrawl
  firebase
  frontend-design
  github
  greptile
  hookify
  jdtls-lsp
  playground
  playwright
  pr-review-toolkit
  ralph-loop
  security-guidance
  sentry
  skill-creator
  stripe
  superpowers
  typescript-lsp
  vercel
)

echo "  [2/4] Installing ${#PLUGINS[@]} plugins..."
for p in "${PLUGINS[@]}"; do
  claude plugin install "$p@claude-plugins-official" 2>/dev/null && echo "    + $p" || true
done

# 3. Disable stripe globally (enable per-project via /neo)
echo "  [3/4] Configuring..."
claude plugin disable stripe@claude-plugins-official 2>/dev/null || true
echo "    stripe: disabled (enable via /neo)"

# 4. Remove stale/unwanted plugins
REMOVE=(
  code-review
  coderabbit
  figma
  postman
  gitlab
  rust-analyzer-lsp
  Notion
  linear
  slack
  supabase
  terraform
  pyright-lsp
  learning-output-style
  mcp-server-dev
  plugin-dev
)

echo "  [4/4] Cleaning stale plugins..."
for p in "${REMOVE[@]}"; do
  claude plugin uninstall "$p@claude-plugins-official" 2>/dev/null && echo "    - $p" || true
done

# python3 alias (Windows only — security-guidance hook needs it)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin"* ]]; then
  if ! command -v python3 &>/dev/null; then
    PYDIR="$(dirname "$(command -v python 2>/dev/null)" 2>/dev/null)"
    if [ -n "$PYDIR" ] && [ -f "$PYDIR/python.exe" ]; then
      cp "$PYDIR/python.exe" "$PYDIR/python3.exe"
      echo "    python3 alias created at $PYDIR"
    else
      echo "    WARNING: python not found. Install Python 3.12+ manually."
    fi
  fi
fi

echo ""
ENABLED=$(claude plugin list 2>/dev/null | grep -c "enabled" || echo "?")
echo "  Done. $ENABLED plugins enabled. Restart Claude Code to apply."
echo ""
