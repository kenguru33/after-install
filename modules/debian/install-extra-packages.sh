#!/bin/bash
set -e

MODULE_NAME="enable-nonfree"
ACTION="${1:-all}"

# === Detect OS ===
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Cannot detect operating system."
  exit 1
fi

# === Ensure Debian ===
if [[ "$OS_ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
  echo "⚠️ This module only supports Debian. Skipping."
  exit 0
fi

# === Debian/Trixie ===
install_debian_nonfree() {
  echo "🔧 Backing up /etc/apt/sources.list..."
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

  echo "📝 Enabling contrib and non-free-firmware..."
  sudo sed -i -E 's/^deb (.*) (trixie[^ ]*) main(.*)$/deb \1 \2 main contrib non-free-firmware/' /etc/apt/sources.list

  echo "🔄 Updating APT sources..."
  sudo apt update

  echo "📦 Installing firmware packages..."
  sudo apt install -y firmware-linux firmware-misc-nonfree
}

clean_debian_nonfree() {
  echo "🧹 Restoring original /etc/apt/sources.list..."
  if [[ -f /etc/apt/sources.list.bak ]]; then
    sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
    sudo apt update
  else
    echo "⚠️ No backup found at /etc/apt/sources.list.bak"
  fi
}

# === Dispatcher ===
case "$ACTION" in
  all | install)
    install_debian_nonfree
    ;;
  config)
    echo "ℹ️ No additional config required for this module."
    ;;
  clean)
    clean_debian_nonfree
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac
