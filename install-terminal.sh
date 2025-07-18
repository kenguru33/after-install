#!/bin/bash
set -e

trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
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
    run_with_spinner "Installing extra packages..." "$MODULES/install-extra-packages.sh all"
    run_with_spinner "Installing Git..." "$MODULES/install-git.sh all"
    run_with_spinner "Installing Zsh..." "$MODULES/install-zsh.sh all"
    run_with_spinner "Installing Nerd Fonts..." "$MODULES/install-nerdfonts.sh all"
    run_with_spinner "Installing Lazyvim..." "$MODULES/install-lazyvim.sh all"
    #run_with_spinner "Installing k8s tools..." "$MODULES/install-k8s-tools.sh all"
    run_with_spinner "Installing k9s..." "$MODULES/install-k9s.sh all"
    $MODULES/../install-terminal-optional.sh all
    ;;
  install)
    run_with_spinner "Installing extra packages..." "$MODULES/install-extra-packages.sh install"
    run_with_spinner "Installing Git..." "$MODULES/install-git.sh install"
    run_with_spinner "Installing Zsh..." "$MODULES/install-zsh.sh install"
    run_with_spinner "Installing Nerd Fonts..." "$MODULES/install-nerdfonts.sh install"
    run_with_spinner "Installing Lazyvim..." "$MODULES/install-lazyvim.sh install"
    ;;
  config)
    run_with_spinner "Configuring extra packages..." "$MODULES/install-extra-packages.sh config"
    run_with_spinner "Configuring Git..." "$MODULES/install-git.sh config"
    run_with_spinner "Configuring Zsh..." "$MODULES/install-zsh.sh config"
    run_with_spinner "Configuring Nerd Fonts..." "$MODULES/install-nerdfonts.sh config"
    run_with_spinner "Configuring Lazyvim..." "$MODULES/install-lazyvim.sh config"
    ;;
  clean)
    run_with_spinner "Cleaning Git config..." "$MODULES/install-git.sh clean"
    run_with_spinner "Cleaning Nerd Fonts..." "$MODULES/install-nerdfonts.sh clean"
    run_with_spinner "Cleaning Zsh..." "$MODULES/install-zsh.sh clean"
    run_with_spinner "Cleaning extra packages..." "$MODULES/install-extra-packages.sh clean"
    run_with_spinner "Cleaning Lazyvim..." "$MODULES/install-lazyvim.sh clean"
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac

echo "✅ Terminal environment '$ACTION' completed successfully!"
