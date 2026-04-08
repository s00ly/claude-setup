#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Claude Code Plugin Sync — Declarative
# Reads plugins.txt manifest and converges to desired state.
# Standalone: bash sync-plugins.sh
# ──────────────────────────────────────────────────────────
set -e

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
echo "  Claude Code — Plugin Sync"
echo "  ──────────────────────────────"
echo ""

# ── 1. Update marketplace ──────────────────────────────────
echo "  [1/5] Updating marketplace..."
claude plugin marketplace update 2>/dev/null || true

# ── 2. Parse manifest ──────────────────────────────────────
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

# ── 3. Install missing, enable/disable as needed ──────────
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

# ── 4. Remove anything NOT in manifest ─────────────────────
echo "  [3/5] Removing unlisted plugins..."
INSTALLED=$(claude plugin list 2>/dev/null | grep "@$MARKETPLACE" | sed "s/.*❯ //" | sed "s/@$MARKETPLACE//")
for p in $INSTALLED; do
  FOUND=false
  for w in "${ALL_WANT[@]}"; do
    if [ "$p" = "$w" ]; then FOUND=true; break; fi
  done
  if [ "$FOUND" = false ]; then
    claude plugin uninstall "$p@$MARKETPLACE" 2>/dev/null && echo "    - $p" || true
  fi
done

# ── 5. Sync settings.json (non-plugin fields only) ────────
echo "  [4/5] Syncing settings..."
PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
if [ -f "$SETTINGS_SRC" ]; then
  mkdir -p "$HOME/.claude"
  if [ -f "$SETTINGS_DST" ] && [ -n "$PY" ]; then
    # Convert MSYS paths to Windows paths for Python
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

# ── 6. python3 alias (Windows only — before verify) ───────
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin"* ]]; then
  if ! command -v python3 &>/dev/null; then
    PYDIR="$(dirname "$(command -v python 2>/dev/null)" 2>/dev/null)"
    if [ -n "$PYDIR" ] && [ -f "$PYDIR/python.exe" ]; then
      cp "$PYDIR/python.exe" "$PYDIR/python3.exe"
      echo "  python3 alias created"
    fi
  fi
fi

# ── 7. Verify ─────────────────────────────────────────────
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
