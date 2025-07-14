#!/bin/bash
set -e

MODULE_NAME="blackbox-terminal"
SCHEME_DIR="$HOME/.local/share/blackbox/schemes"
PALETTE_NAME="catppuccin-mocha"
ACTION="${1:-all}"

install_blackbox() {
  echo "📦 Installing BlackBox Terminal from apt..."

  if ! command -v blackbox &>/dev/null; then
    sudo apt update
    sudo apt install -y blackbox-terminal
    echo "✅ BlackBox installed."
  else
    echo "ℹ️ BlackBox is already installed."
  fi
}

install_catppuccin_theme() {
  echo "🎨 Installing Catppuccin Mocha theme..."

  mkdir -p "$SCHEME_DIR"

  if [[ ! -f "$SCHEME_DIR/$PALETTE_NAME.json" ]]; then
    TMP_DIR=$(mktemp -d)
    git clone --depth=1 https://github.com/catppuccin/tilix.git "$TMP_DIR"
    cp "$TMP_DIR/themes/$PALETTE_NAME.json" "$SCHEME_DIR/$PALETTE_NAME.json"
    rm -rf "$TMP_DIR"
    echo "✅ Theme copied to $SCHEME_DIR/$PALETTE_NAME.json"
  else
    echo "ℹ️ Theme already exists."
  fi
}

clean_blackbox() {
  echo "🧼 Cleaning BlackBox installation and themes..."

  sudo apt remove --purge -y blackbox-terminal || true
  rm -rf "$SCHEME_DIR"
  dconf reset -f /com/raggesilver/BlackBox/ || true

  echo "✅ BlackBox removed and cleaned."
}

case "$ACTION" in
  install)
    install_blackbox
    ;;
  config)
    install_catppuccin_theme
    ;;
  clean)
    clean_blackbox
    ;;
  all)
    install_blackbox
    install_catppuccin_theme
    ;;
  *)
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
