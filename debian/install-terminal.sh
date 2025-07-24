#!/bin/bash
set -e
trap 'echo "❌ An error occurred in install-terminal.sh." >&2' ERR

MODULE_NAME="terminal"
ACTION="${1:-all}"
VERBOSE=0

for arg in "$@"; do
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=1
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_module() {
  local script="$1"
  local label="$2"

  echo "🔹 [$MODULE_NAME] $label..."
  "$SCRIPT_DIR/$script" "$ACTION" "${VERBOSE:+--verbose}"
}

case "$ACTION" in
  deps)
    run_module install-base-deps.sh "Installing base dependencies"
    ;;
  install)
    run_module install-zsh.sh "Installing Zsh"
    run_module install-git-config.sh "Installing Git + config"
    run_module install-starship.sh "Installing Starship"
    run_module install-kitty.sh "Installing Kitty"
    run_module install-blackbox-terminal.sh "Installing BlackBox"
    ;;
  config)
    run_module install-zsh.sh "Configuring Zsh"
    run_module install-git-config.sh "Configuring Git"
    run_module install-starship.sh "Configuring Starship"
    run_module install-kitty.sh "Configuring Kitty"
    run_module install-blackbox-terminal.sh "Configuring BlackBox"
    ;;
  clean)
    run_module install-zsh.sh "Cleaning Zsh"
    run_module install-git-config.sh "Cleaning Git"
    run_module install-starship.sh "Cleaning Starship"
    run_module install-kitty.sh "Cleaning Kitty"
    run_module install-blackbox-terminal.sh "Cleaning BlackBox"
    ;;
  all)
    run_module install-base-deps.sh "Installing base dependencies"
    "$0" deps
    "$0" install
    "$0" config
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean] [--verbose]"
    exit 1
    ;;
esac
