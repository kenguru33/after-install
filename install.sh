#!/bin/bash
set -e

trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Load modules ===
MODULES="$SCRIPT_DIR/modules"

# === Check for required scripts ===
if [[ ! -x "$MODULES/check-sudo.sh" ]]; then
  echo "❌ Missing or non-executable: $MODULES/check-sudo.sh"
  exit 1
fi

# === Run sudo check ===
"$MODULES/check-sudo.sh"

# === Determine action (default: all) ===
ACTION="${1:-all}"

# === Check for GNOME Desktop ===
if command -v gnome-shell &>/dev/null; then
  echo "🖥️ GNOME desktop detected. Running install-desktop.sh..."
  "$SCRIPT_DIR/install-desktop.sh" "$ACTION"
else
  echo "💻 GNOME not detected. Running install-terminal.sh..."
  "$SCRIPT_DIR/install-terminal.sh" "$ACTION"
fi

echo "✅ System '$ACTION' setup completed successfully!"
