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

run_with_spinner() {
  TITLE="$1"
  CMD="$2"
  gum spin --title "$TITLE" -- bash -c "$CMD"
}

case "$ACTION" in
  all)
    run_with_spinner "Installing terminal environment..." "$MODULES/../install-terminal.sh all"
    run_with_spinner "Installing GNOME config..." "$MODULES/install-gnome-config.sh all"
    run_with_spinner "Installing GNOME extensions..." "$MODULES/install-gnome-extensions.sh all"
    # run_with_spinner "Installing Orchis theme..." "$MODULES/install-orchis-theme.sh all"
    run_with_spinner "Installing Kitty terminal..." "$MODULES/install-kitty.sh all"
    run_with_spinner "Installing VS Code..." "$MODULES/install-vscode.sh all"
    run_with_spinner "Installing Chrome..." "$MODULES/install-chrome.sh all"
    run_with_spinner "Installing BlackBox Terminal..." "$MODULES/install-blackbox-terminal.sh all"
    run_with_spinner "Installing Papirus icon theme..." "$MODULES/install-papirus.sh all"
    ;;
  install)
    run_with_spinner "Installing GNOME extensions..." "$MODULES/install-gnome-extensions.sh install"
    # run_with_spinner "Installing Orchis theme..." "$MODULES/install-orchis-theme.sh install"
    run_with_spinner "Installing GNOME config..." "$MODULES/install-gnome-config.sh install"
    run_with_spinner "Installing Kitty terminal..." "$MODULES/install-kitty.sh install"
    run_with_spinner "Installing VS Code..." "$MODULES/install-vscode.sh install"
    run_with_spinner "Installing terminal environment..." "$MODULES/../install-terminal.sh install"
    run_with_spinner "Installing Chrome..." "$MODULES/install-chrome.sh install"
    run_with_spinner "Installing BlackBox Terminal..." "$MODULES/install-blackbox-terminal.sh install"
    run_with_spinner "Installing Papirus icon theme..." "$MODULES/install-papirus.sh install"
    ;;
  config)
    run_with_spinner "Configuring GNOME extensions..." "$MODULES/install-gnome-extensions.sh config"
    # run_with_spinner "Configuring Orchis theme..." "$MODULES/install-orchis-theme.sh config"
    run_with_spinner "Configuring GNOME config..." "$MODULES/install-gnome-config.sh config"
    run_with_spinner "Configuring Papirus icon theme..." "$MODULES/install-papirus.sh config"
    run_with_spinner "Configuring Kitty terminal..." "$MODULES/install-kitty.sh config"
    run_with_spinner "Configuring VS Code..." "$MODULES/install-vscode.sh config"
    run_with_spinner "Configuring terminal environment..." "$MODULES/../install-terminal.sh config"
    run_with_spinner "Configuring Chrome..." "$MODULES/install-chrome.sh config"
    run_with_spinner "Configuring BlackBox Terminal..." "$MODULES/install-blackbox-terminal.sh config"
    ;;
  clean)
    # run_with_spinner "Cleaning Orchis theme..." "$MODULES/install-orchis-theme.sh clean"
    run_with_spinner "Cleaning GNOME config..." "$MODULES/install-gnome-config.sh clean"
    run_with_spinner "Cleaning Papirus icon theme..." "$MODULES/install-papirus.sh clean"
    run_with_spinner "Cleaning GNOME extensions..." "$MODULES/install-gnome-extensions.sh clean"
    run_with_spinner "Cleaning Kitty terminal..." "$MODULES/install-kitty.sh clean"
    run_with_spinner "Cleaning VS Code..." "$MODULES/install-vscode.sh clean"
    run_with_spinner "Cleaning terminal environment..." "$MODULES/../install-terminal.sh clean"
    run_with_spinner "Cleaning Chrome..." "$MODULES/install-chrome.sh clean"
    run_with_spinner "Cleaning BlackBox Terminal..." "$MODULES/install-blackbox-terminal.sh clean"
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac

echo "✅ Desktop environment '$ACTION' completed successfully!"
