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
    "$MODULES/install-extra-packages.sh" all
    "$MODULES/install-git.sh" all
    "$MODULES/install-zsh.sh" all
    "$MODULES/install-nerdfonts.sh" all
    ;;
  install)
    "$MODULES/install-extra-packages.sh" install
    "$MODULES/install-git.sh" install
    "$MODULES/install-zsh.sh" install
    "$MODULES/install-nerdfonts.sh" install
    ;;
  config)
    "$MODULES/install-extra-packages.sh" config
    "$MODULES/install-git.sh" config
    "$MODULES/install-zsh.sh" config
    "$MODULES/install-nerdfonts.sh" config
    ;;
  clean)
    "$MODULES/install-git.sh" clean
    "$MODULES/install-nerdfonts.sh" clean
    "$MODULES/install-zsh.sh" clean
    "$MODULES/install-extra-packages.sh" clean
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac

echo "✅ Terminal environment '$ACTION' completed successfully!"
