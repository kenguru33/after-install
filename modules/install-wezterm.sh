#!/bin/bash
set -e

MODULE_NAME="wezterm"
CONFIG_DIR="$HOME/.config/wezterm"
CONFIG_FILE="$CONFIG_DIR/wezterm.lua"
APT_SOURCE="/etc/apt/sources.list.d/wezterm.list"
KEYRING="/usr/share/keyrings/wezterm-fury.gpg"

ACTION="${1:-all}"

install_wezterm() {
  echo "📦 Installing WezTerm via official APT repo..."

  if ! command -v wezterm &>/dev/null; then
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o "$KEYRING"
    echo "deb [signed-by=$KEYRING] https://apt.fury.io/wez/ * *" | sudo tee "$APT_SOURCE" > /dev/null
    sudo chmod 644 "$KEYRING"
    sudo apt update
    sudo apt install -y wezterm
    echo "✅ WezTerm installed."
  else
    echo "ℹ️ WezTerm already installed."
  fi
}

config_wezterm() {
  echo "⚙️ Writing wezterm.lua config..."
  mkdir -p "$CONFIG_DIR"

  cat > "$CONFIG_FILE" <<'EOF'
local wezterm = require 'wezterm'
local config = {}

config.color_scheme = "Catppuccin Mocha"
config.enable_wayland = true
config.front_end = "OpenGL"
config.window_decorations = "TITLE|INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Gnome"
config.hide_tab_bar_if_only_one_tab = true

config.window_frame = {
  active_titlebar_bg = wezterm.color.parse("#1e1e2e"),
  inactive_titlebar_bg = wezterm.color.parse("#1e1e2e"),
}

config.window_padding = {
  left = 10,
  right = 10,
  top = 5,
  bottom = 5,
}

return config
EOF

  echo "✅ Config written to $CONFIG_FILE"
}

clean_wezterm() {
  echo "🧹 Cleaning WezTerm config and installation..."

  echo "🗑️ Removing config at $CONFIG_DIR"
  rm -rf "$CONFIG_DIR"

  if dpkg -l | grep -q wezterm; then
    echo "📦 Uninstalling wezterm package..."
    sudo apt remove -y wezterm
  fi

  if [[ -f "$APT_SOURCE" ]]; then
    echo "🧽 Removing APT source: $APT_SOURCE"
    sudo rm -f "$APT_SOURCE"
  fi

  if [[ -f "$KEYRING" ]]; then
    echo "🧽 Removing GPG keyring: $KEYRING"
    sudo rm -f "$KEYRING"
  fi

  sudo apt update
  echo "✅ WezTerm fully removed."
}

case "$ACTION" in
  all)
    install_wezterm
    config_wezterm
    ;;
  install)
    install_wezterm
    ;;
  config)
    config_wezterm
    ;;
  clean)
    clean_wezterm
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac
