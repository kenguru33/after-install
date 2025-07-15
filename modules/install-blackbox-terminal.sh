#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="blackbox-terminal"
SCHEMA_ID="com.raggesilver.BlackBox"
SCHEME_DIR="$HOME/.local/share/blackbox/schemes"
PALETTE_NAME="Catppuccin Mocha"
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
    cp "$TMP_DIR/themes/catppuccin-mocha.json" "$SCHEME_DIR/$PALETTE_NAME.json"
    rm -rf "$TMP_DIR"
    echo "✅ Theme installed to $SCHEME_DIR"
  else
    echo "ℹ️ Theme already installed."
  fi
}

config_blackbox() {
  echo "🎨 Configuring BlackBox with Catppuccin Mocha + Hack Nerd Font Mono..."

  if gsettings list-schemas | grep -q "$SCHEMA_ID"; then
    gsettings set "$SCHEMA_ID" font 'Hack Nerd Font Mono 11'
    gsettings set "$SCHEMA_ID" opacity 0.95
    gsettings set "$SCHEMA_ID" terminal-padding '12px'
    gsettings set "$SCHEMA_ID" scrollback-lines 10000
    gsettings set "$SCHEMA_ID" theme-dark "$PALETTE_NAME"
    gsettings set "$SCHEMA_ID" style-preference 'dark'
    gsettings set "$SCHEMA_ID" cursor-shape 'block'
    gsettings set "$SCHEMA_ID" cursor-blink-mode 'system'
    gsettings set "$SCHEMA_ID" terminal-bell false
    gsettings set "$SCHEMA_ID" pretty true
    echo "✅ Configuration applied via GSettings."
  else
    echo "⚠️ GSettings schema '$SCHEMA_ID' not found. Launch BlackBox once, then re-run: $0 config"
  fi
}

clean_blackbox() {
  echo "🗑️ Cleaning up BlackBox terminal and theme files..."
  sudo apt purge -y blackbox-terminal || true
  rm -f "$SCHEME_DIR/$PALETTE_NAME.json"
  echo "✅ Cleanup done."
}

case "$ACTION" in
  install)
    install_blackbox
    install_catppuccin_theme
    ;;
  config)
    config_blackbox
    ;;
  clean)
    clean_blackbox
    ;;
  all)
    install_blackbox
    install_catppuccin_theme
    config_blackbox
    ;;
  *)
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
