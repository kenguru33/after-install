#!/bin/bash
set -e

MODULE_NAME="lens"
APT_SOURCE="/etc/apt/sources.list.d/lens.list"
KEYRING="/usr/share/keyrings/lens-archive-keyring.gpg"
ACTION="${1:-all}"

install_lens() {
  echo "📦 Installing Lens Desktop..."

  if ! command -v lens &>/dev/null; then
    echo "🔑 Adding GPG key..."
    curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | sudo tee "$KEYRING" > /dev/null

    echo "📁 Adding APT source..."
    echo "deb [arch=amd64 signed-by=$KEYRING] https://downloads.k8slens.dev/apt/debian stable main" \
      | sudo tee "$APT_SOURCE" > /dev/null

    echo "🔄 Updating package lists..."
    sudo apt update

    echo "⬇️ Installing lens..."
    sudo apt install -y lens

    echo "✅ Lens Desktop installed."
  else
    echo "ℹ️ Lens is already installed."
  fi
}

clean_lens() {
  echo "🧹 Removing Lens Desktop..."

  sudo apt remove -y lens || true
  sudo rm -f "$APT_SOURCE"
  sudo rm -f "$KEYRING"
  sudo apt update

  echo "✅ Lens Desktop removed."
}

case "$ACTION" in
  install) install_lens ;;
  clean) clean_lens ;;
  all)
    install_lens
    ;;
  *)
    echo "Usage: $0 [install|clean|all]"
    exit 1
    ;;
esac
