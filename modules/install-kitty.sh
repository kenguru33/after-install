#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

CONFIG_DIR="$HOME/.config/kitty"
FONT_NAME="Hack Nerd Font Mono"

install_kitty() {
  echo "🐱 Installing Kitty terminal via apt..."

  if command -v kitty &>/dev/null; then
    echo "✅ Kitty is already installed."
    return
  fi

  sudo apt update
  sudo apt install -y kitty
  echo "✅ Kitty installed."
}

check_font_installed() {
  echo "🔍 Checking for required font: $FONT_NAME..."
  if ! fc-list | grep -qi "$FONT_NAME"; then
    echo "❌ '$FONT_NAME' not found."
    echo "👉 Please run: ./install-nerdfont-hack.sh install"
    exit 1
  fi
  echo "✅ Font '$FONT_NAME' is installed."
}

configure_kitty() {
  echo "🎨 Configuring Kitty..."

  mkdir -p "$CONFIG_DIR"

  cat > "$CONFIG_DIR/kitty.conf" <<EOF
# Font
font_family      $FONT_NAME
font_size        11.0
enable_ligatures yes

# Padding
window_padding_width 8

# Scrollback and performance
scrollback_lines 10000
repaint_delay 10
input_delay 2
sync_to_monitor yes

# Optional: Disable window title text
# window_title_format ""
# tab_title_template ""

# Colors: Catppuccin Mocha
background       #1e1e2e
foreground       #cdd6f4
cursor           #f5e0dc
selection_background #cdd6f4
selection_foreground #1e1e2e

color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
EOF

  echo "✅ Kitty configuration written to $CONFIG_DIR/kitty.conf"
}

clean_kitty() {
  echo "🧹 Removing Kitty config..."
  rm -rf "$CONFIG_DIR"
  echo "✅ Kitty config removed."

  echo "🧽 Uninstalling Kitty..."
  sudo apt remove --purge -y kitty || true
  sudo apt autoremove -y
  echo "✅ Kitty uninstalled."
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install Kitty and apply config"
  echo "  install  Install Kitty using apt"
  echo "  config   Create Kitty config (requires Hack Nerd Font)"
  echo "  clean    Remove Kitty config and uninstall"
}

case "$1" in
  all)
    install_kitty
    check_font_installed
    configure_kitty
    ;;
  install)
    install_kitty
    ;;
  config)
    check_font_installed
    configure_kitty
    ;;
  clean)
    clean_kitty
    ;;
  *)
    show_help
    ;;
esac
