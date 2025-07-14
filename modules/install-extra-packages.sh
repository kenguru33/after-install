#!/bin/bash
set -e

MODULE_NAME="enable-nonfree"
ACTION="${1:-all}"
SOURCES_LIST="/etc/apt/sources.list"
BACKUP="/etc/apt/sources.list.bak"

install_nonfree_sources() {
  echo "🔧 Backing up sources.list to $BACKUP..."
  sudo cp "$SOURCES_LIST" "$BACKUP"

  echo "📝 Enabling contrib and non-free-firmware..."
  sudo sed -i -E 's/^deb (.*) (trixie[^ ]*) main(.*)$/deb \1 \2 main contrib non-free-firmware/' "$SOURCES_LIST"

  echo "🔄 Updating APT sources..."
  sudo apt update
}

install_firmware_packages() {
  echo "📦 Installing recommended firmware packages..."
  sudo apt install -y firmware-linux firmware-misc-nonfree
}

clean_nonfree_sources() {
  echo "🧹 Restoring original sources.list from backup..."
  if [[ -f "$BACKUP" ]]; then
    sudo cp "$BACKUP" "$SOURCES_LIST"
    sudo apt update
  else
    echo "⚠️  No backup found at $BACKUP"
  fi
}

case "$ACTION" in
  all)
    install_nonfree_sources
    install_firmware_packages
    ;;
  install)
    install_nonfree_sources
    ;;
  config)
    install_firmware_packages
    ;;
  clean)
    clean_nonfree_sources
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac
