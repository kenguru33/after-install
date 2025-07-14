#!/bin/bash
set -e

trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="$SCRIPT_DIR/modules"

# === Check for required scripts ===
if [[ ! -x "$MODULES/check-sudo.sh" ]]; then
  echo "❌ Missing or non-executable: $MODULES/check-sudo.sh"
  exit 1
fi

# === Run sudo check ===
"$MODULES/check-sudo.sh"

# === Dispatch actions to modules ===
ACTION="${1:-all}"

case "$ACTION" in
  all)
    "$MODULES/../install-terminal.sh" all
    "$MODULES/install-gnome-extensions.sh" all
    "$MODULES/install-orchis-theme.sh" all
    "$MODULES/install-kitty.sh" all
    "$MODULES/install-vscode.sh" all
    "$MODULES/install-chrome.sh" all

    ;;
  install)
    "$MODULES/install-gnome-extensions.sh" install
    "$MODULES/install-orchis-theme.sh" install
    "$MODULES/install-kitty.sh" install
    "$MODULES/install-vscode.sh" install
    "$MODULES/../install-terminal.sh" install
    "$MODULES/install-chrome.sh" install
    "$MODULES/install-blackbox.sh" install
    ;;
  config)
    "$MODULES/install-gnome-extensions.sh" config
    "$MODULES/install-orchis-theme.sh" config
    "$MODULES/install-kitty.sh" config
    "$MODULES/install-vscode.sh" config
    "$MODULES/../install-terminal.sh" config
    "$MODULES/install-chrome.sh" config
    "$MODULES/install-blackbox.sh" config
    ;;
  clean)
    "$MODULES/install-orchis-theme.sh" clean
    "$MODULES/install-gnome-extensions.sh" clean
    "$MODULES/install-kitty.sh" clean
    "$MODULES/install-vscode.sh" clean
    "$MODULES/../install-terminal.sh" clean
    "$MODULES/install-chrome.sh" clean
    "$MODULES/install-blackbox.sh" clean
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac

echo "✅ Desktop environment '$ACTION' completed successfully!"
