#!/bin/bash
set -e

MODULE_NAME="1password"
ACTION="${1:-all}"

KEYRING="/usr/share/keyrings/1password-archive-keyring.gpg"
APT_SOURCE="/etc/apt/sources.list.d/1password.list"

install_1password() {
  echo "🔐 Adding 1Password signing key (force overwrite)..."
  sudo rm -f "$KEYRING"
  curl -sS https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor --output "$KEYRING"

  echo "➕ Adding 1Password APT repository (force overwrite)..."
  sudo rm -f "$APT_SOURCE"
  echo "deb [arch=amd64 signed-by=$KEYRING] https://downloads.1password.com/linux/debian/amd64 stable main" \
    | sudo tee "$APT_SOURCE" > /dev/null

  echo "📦 Updating APT and installing 1Password..."
  sudo apt update
  sudo apt install -y 1password

  echo "✅ 1Password installed successfully."
}

clean_1password() {
  echo "🧹 Removing 1Password and its APT source..."
  sudo apt remove --purge -y 1password || true
  sudo rm -f "$APT_SOURCE"
  sudo rm -f "$KEYRING"
  sudo apt update
  echo "✅ 1Password and its repo removed."
}

case "$ACTION" in
  install) install_1password ;;
  clean)   clean_1password ;;
  all)     install_1password ;;
  *)
    echo "Usage: $0 [install|clean|all]"
    exit 1
    ;;
esac
