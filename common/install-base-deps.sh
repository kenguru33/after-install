#!/bin/bash
set -e
trap 'echo "❌ An error occurred in install-base-deps.sh." >&2' ERR

MODULE_NAME="base-deps"
ACTION="${1:-all}"
VERBOSE=0

for arg in "$@"; do
  [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && VERBOSE=1
done

# Detect OS
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  ID="$ID"
else
  echo "❌ Cannot detect OS."
  exit 1
fi

install_dependencies() {
  echo "🔧 [$MODULE_NAME] Installing curl, wget, unzip..."

  case "$ID" in
    debian|ubuntu)
      sudo apt update
      sudo apt install -y curl wget unzip tar ca-certificates
      ;;
    fedora)
      sudo dnf install -y curl wget unzip tar ca-certificates
      ;;
    *)
      echo "❌ Unsupported distro: $ID"
      exit 1
      ;;
  esac

  echo "✅ [$MODULE_NAME] Dependencies installed."
}

clean_dependencies() {
  echo "🧹 [$MODULE_NAME] Removing base tools..."

  case "$ID" in
    debian|ubuntu)
      sudo apt remove --purge -y curl wget unzip tar ca-certificates
      ;;
    fedora)
      sudo dnf remove -y curl wget unzip tar ca-certificates
      ;;
  esac

  echo "✅ [$MODULE_NAME] Base dependencies removed."
}

case "$ACTION" in
  deps|install|all)
    install_dependencies
    ;;
  clean)
    clean_dependencies
    ;;
  *)
    echo "✅ [$MODULE_NAME] No config step needed."
    ;;
esac
