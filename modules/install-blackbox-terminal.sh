#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="blackbox-terminal"
SCHEME_DIR="$HOME/.local/share/blackbox/schemes"
PALETTE_NAME="catppuccin-mocha"
SCHEMA_ID="com.raggesilver.BlackBox"
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
    echo "✅ Theme installed to $SCHEME_DIR"
  else
    echo "ℹ️ Theme already installed."
  fi
}

config_blackbox() {
  echo "🎨 Configuring BlackBox with Catppuccin Mocha + Hack Nerd Font Mono..."

  if gsettings list-schemas | grep -q "$SCHEMA_ID"; then
    gsettings set "$SCHEMA_ID" font 'Hack Nerd Font Mono 11'
    gsettings set "$SCHEMA_ID" theme-dark "$PALETTE_NAME"
    gsettings set "$SCHEMA_ID" theme-light "$PALETTE_NAME"
    gsettings set "$SCHEMA_ID" theme-dark "$PALETTE_NAME"
    gsettings set "$SCHEMA_ID" terminal-padding '(12, 12, 12, 12)'

    echo "✅ Configuration applied via GSettings."
  else
    echo "⚠️ GSettings schema '$SCHEMA_ID' not found. You may need to launch BlackBox once or restart GNOME."
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
