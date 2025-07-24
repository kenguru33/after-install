#!/bin/bash
set -e
trap 'echo "❌ An error occurred in $0."' ERR

ACTION="${1:-all}"
VERBOSE=0

for arg in "$@"; do
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=1
done

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_module() {
  local script="$1"
  local label="$2"

  echo "🔹 Running $label..."
  "$DIR/$script" "$ACTION" "${VERBOSE:+--verbose}"
}

case "$ACTION" in
  all)
    run_module install-terminal.sh "Terminal Setup"
    run_module install-desktop.sh "Desktop Setup"
    run_module install-optional.sh "Optional Tools"
    ;;
  deps|install|config|clean)
    run_module install-terminal.sh "Terminal Setup"
    run_module install-desktop.sh "Desktop Setup"
    run_module install-optional.sh "Optional Tools"
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: install.sh [all|deps|install|config|clean] [--verbose]"
    exit 1
    ;;
esac
