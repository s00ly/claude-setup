#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Claude Code Plugin Sync — Declarative
# Reads plugins.txt manifest and converges to desired state.
#
# Usage:
#   bash sync-plugins.sh          # full sync
#   bash sync-plugins.sh --check  # audit only, no changes
# ──────────────────────────────────────────────────────────
set -e

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then CHECK_ONLY=true; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/plugins.txt"
SETTINGS_SRC="$SCRIPT_DIR/settings.json"
SETTINGS_DST="$HOME/.claude/settings.json"
MARKETPLACE="claude-plugins-official"

if [ ! -f "$MANIFEST" ]; then
  echo "  ERROR: plugins.txt not found at $MANIFEST"
  exit 1
fi

echo ""
if [ "$CHECK_ONLY" = true ]; then
  echo "  Claude Code — Plugin Audit"
else
  echo "  Claude Code — Plugin Sync"
fi
echo "  ──────────────────────────────"
echo ""

# ── 1. Parse manifest ─────────────────────────────────────
declare -a WANT_ENABLED=()
declare -a WANT_DISABLED=()

while IFS= read -r line; do
  line="${line%%#*}"          # strip comments
  line="${line// /}"          # strip whitespace
  [ -z "$line" ] && continue # skip blank
  if [[ "$line" == !* ]]; then
    WANT_DISABLED+=("${line:1}")
  else
    WANT_ENABLED+=("$line")
  fi
done < "$MANIFEST"

ALL_WANT=("${WANT_ENABLED[@]}" "${WANT_DISABLED[@]}")
echo "  Manifest: ${#WANT_ENABLED[@]} enabled, ${#WANT_DISABLED[@]} disabled"

# ── 2. Get current state ─────────────────────────────────
PLUGIN_DUMP=$(claude plugin list 2>/dev/null)

if [ "$CHECK_ONLY" = true ]; then
  # ── AUDIT MODE ──────────────────────────────────────────
  echo ""
  ERRORS=0
  MISSING=()
  EXTRA=()
  WRONG_STATE=()

  # Check wanted plugins exist with correct state
  for p in "${WANT_ENABLED[@]}"; do
    if ! echo "$PLUGIN_DUMP" | grep -q "$p@$MARKETPLACE"; then
      MISSING+=("$p")
      ERRORS=$((ERRORS + 1))
    elif ! echo "$PLUGIN_DUMP" | grep -A3 "$p@$MARKETPLACE" | grep -q "✔ enabled"; then
      WRONG_STATE+=("$p (should be enabled)")
      ERRORS=$((ERRORS + 1))
    fi
  done

  for p in "${WANT_DISABLED[@]}"; do
    if ! echo "$PLUGIN_DUMP" | grep -q "$p@$MARKETPLACE"; then
      MISSING+=("$p")
      ERRORS=$((ERRORS + 1))
    elif ! echo "$PLUGIN_DUMP" | grep -A3 "$p@$MARKETPLACE" | grep -q "disabled"; then
      WRONG_STATE+=("$p (should be disabled)")
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check for plugins not in manifest
  INSTALLED=$(echo "$PLUGIN_DUMP" | grep "@$MARKETPLACE" | sed "s/.*❯ //" | sed "s/@$MARKETPLACE//" | tr -d ' ')
  for p in $INSTALLED; do
    FOUND=false
    for w in "${ALL_WANT[@]}"; do
      if [ "$p" = "$w" ]; then FOUND=true; break; fi
    done
    if [ "$FOUND" = false ]; then
      EXTRA+=("$p")
      ERRORS=$((ERRORS + 1))
    fi
  done

  TOTAL=$(echo "$PLUGIN_DUMP" | grep -c "❯" || echo "0")

  # Report
  if [ ${#MISSING[@]} -gt 0 ]; then
    echo "  MISSING (need install):"
    for p in "${MISSING[@]}"; do echo "    - $p"; done
  fi
  if [ ${#EXTRA[@]} -gt 0 ]; then
    echo "  EXTRA (not in manifest):"
    for p in "${EXTRA[@]}"; do echo "    + $p"; done
  fi
  if [ ${#WRONG_STATE[@]} -gt 0 ]; then
    echo "  WRONG STATE:"
    for p in "${WRONG_STATE[@]}"; do echo "    ~ $p"; done
  fi

  echo ""
  if [ "$ERRORS" -eq 0 ]; then
    echo "  COMPLIANT: $TOTAL plugins match manifest. No action needed."
  else
    echo "  NON-COMPLIANT: $ERRORS issue(s). Run 'bash sync-plugins.sh' to fix."
  fi
  echo ""
  exit "$ERRORS"
fi

# ── FULL SYNC MODE ────────────────────────────────────────

# ── 3. Update marketplace ─────────────────────────────────
echo "  [1/5] Updating marketplace..."
claude plugin marketplace update 2>/dev/null || true

# ── 4. Install missing, enable/disable as needed ─────────
echo "  [2/5] Installing & configuring..."
for p in "${WANT_ENABLED[@]}"; do
  claude plugin install "$p@$MARKETPLACE" 2>/dev/null || true
  claude plugin enable "$p@$MARKETPLACE" 2>/dev/null || true
done

for p in "${WANT_DISABLED[@]}"; do
  claude plugin install "$p@$MARKETPLACE" 2>/dev/null || true
  claude plugin disable "$p@$MARKETPLACE" 2>/dev/null || true
  echo "    $p: disabled"
done

# ── 5. Remove anything NOT in manifest ────────────────────
echo "  [3/5] Removing unlisted plugins..."
INSTALLED=$(echo "$PLUGIN_DUMP" | grep "@$MARKETPLACE" | sed "s/.*❯ //" | sed "s/@$MARKETPLACE//" | tr -d ' ')
for p in $INSTALLED; do
  FOUND=false
  for w in "${ALL_WANT[@]}"; do
    if [ "$p" = "$w" ]; then FOUND=true; break; fi
  done
  if [ "$FOUND" = false ]; then
    claude plugin uninstall "$p@$MARKETPLACE" 2>/dev/null && echo "    - $p" || true
  fi
done

# ── 6. Sync settings.json (non-plugin fields only) ───────
echo "  [4/5] Syncing settings..."
PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
if [ -f "$SETTINGS_SRC" ]; then
  mkdir -p "$HOME/.claude"
  if [ -f "$SETTINGS_DST" ] && [ -n "$PY" ]; then
    PY_DST="$SETTINGS_DST"
    PY_SRC="$SETTINGS_SRC"
    if command -v cygpath &>/dev/null; then
      PY_DST="$(cygpath -w "$SETTINGS_DST")"
      PY_SRC="$(cygpath -w "$SETTINGS_SRC")"
    fi
    "$PY" -c "
import json
with open(r'$PY_DST') as f: dst = json.load(f)
with open(r'$PY_SRC') as f: src = json.load(f)
for k, v in src.items():
    if k != 'enabledPlugins':
        dst[k] = v
with open(r'$PY_DST', 'w') as f: json.dump(dst, f, indent=2)
print('    settings.json merged')
" 2>/dev/null || echo "    settings.json merge skipped (python unavailable)"
  elif [ ! -f "$SETTINGS_DST" ]; then
    cp "$SETTINGS_SRC" "$SETTINGS_DST"
    echo "    settings.json created"
  fi
fi

# ── 7. python3 alias (Windows only) ──────────────────────
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin"* ]]; then
  if ! command -v python3 &>/dev/null; then
    PYDIR="$(dirname "$(command -v python 2>/dev/null)" 2>/dev/null)"
    if [ -n "$PYDIR" ] && [ -f "$PYDIR/python.exe" ]; then
      cp "$PYDIR/python.exe" "$PYDIR/python3.exe"
      echo "  python3 alias created"
    fi
  fi
fi

# ── 8. Verify ─────────────────────────────────────────────
echo "  [5/5] Verifying..."
ERRORS=0
PLUGIN_DUMP=$(claude plugin list 2>/dev/null)

for p in "${WANT_ENABLED[@]}"; do
  if ! echo "$PLUGIN_DUMP" | grep -A3 "$p@$MARKETPLACE" | grep -q "✔ enabled"; then
    echo "    FAIL: $p should be enabled"
    ERRORS=$((ERRORS + 1))
  fi
done

for p in "${WANT_DISABLED[@]}"; do
  if ! echo "$PLUGIN_DUMP" | grep -A3 "$p@$MARKETPLACE" | grep -q "disabled"; then
    echo "    FAIL: $p should be disabled"
    ERRORS=$((ERRORS + 1))
  fi
done

TOTAL=$(echo "$PLUGIN_DUMP" | grep -c "❯" || echo "0")
EXPECTED=${#ALL_WANT[@]}

if [ "$TOTAL" != "$EXPECTED" ]; then
  echo "    FAIL: expected $EXPECTED plugins, found $TOTAL"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "  OK: $TOTAL plugins ($EXPECTED expected), 0 errors."
else
  echo "  WARN: $ERRORS verification error(s). Review above."
fi

echo ""
echo "  Restart Claude Code to apply changes."
echo ""
