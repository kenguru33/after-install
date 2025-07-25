#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

MODULE_NAME="kitty"
CONFIG_DIR="$HOME/.config/kitty"
FONT_NAME="Hack Nerd Font Mono"
ACTION="${1:-all}"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect OS."
  exit 1
fi

# === Dependencies ===
DEPS_DEBIAN=(kitty)
DEPS_FEDORA=(kitty)

install_deps() {
  echo "📦 Installing dependencies for $OS_ID..."
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt update
    sudo apt install -y "${DEPS_DEBIAN[@]}"
  elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf install -y "${DEPS_FEDORA[@]}"
  else
    echo "❌ Unsupported OS: $OS_ID"
    exit 1
  fi
}

install_kitty() {
  echo "🐱 Installing Kitty terminal..."
  if command -v kitty &>/dev/null; then
    echo "✅ Kitty is already installed."
    return
  fi
  install_deps
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
font_family          Hack Nerd Font Mono
font_size            11.0
enable_ligatures     yes

# Padding
window_padding_width 8

# Scrollback and performance
scrollback_lines     10000
repaint_delay        10
input_delay          2
sync_to_monitor      yes


# Titlebar and tab titles show path only (with ~ for home)
window_title_format "{shrink_path(cwd)}"
tab_title_template "{shrink_path(cwd)}"

# Hide all window decorations
hide_window_decorations yes

# Allow dynamic tab title updates
allow_remote_control yes

# Cursor
cursor               #f5e0dc
cursor_text_color    #1e1e2e

# Selection
selection_background #f5e0dc
selection_foreground #1e1e2e

# URL underline color
url_color            #f5e0dc

# Border colors
active_border_color     #b4befe
inactive_border_color   #6c7086
bell_border_color       #f9e2af

# Tab bar colors and styles
active_tab_foreground     #11111b
active_tab_background     #cba6f7
inactive_tab_foreground   #cdd6f4
inactive_tab_background   #181825
tab_bar_background        #11111b
tab_bar_min_tabs          1
tab_bar_style             powerline
tab_powerline_style       slanted

# Marks
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# 16 terminal colors

# black
color0  #45475a
color8  #585b70

# red
color1  #f38ba8
color9  #f38ba8

# green
color2  #a6e3a1
color10 #a6e3a1

# yellow
color3  #f9e2af
color11 #f9e2af

# blue
color4  #89b4fa
color12 #89b4fa

# magenta
color5  #f5c2e7
color13 #f5c2e7

# cyan
color6  #94e2d5
color14 #94e2d5

# white
color7  #bac2de
color15 #a6adc8

# Background and foreground
background #1e1e2e
foreground #cdd6f4

EOF

  echo "✅ Kitty configuration written to $CONFIG_DIR/kitty.conf"
}

clean_kitty() {
  echo "🧹 Removing Kitty config..."
  rm -rf "$CONFIG_DIR"
  echo "✅ Kitty config removed."

  echo "🧽 Uninstalling Kitty..."
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt remove --purge -y kitty || true
    sudo apt autoremove -y
  elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf remove -y kitty || true
  fi
  echo "✅ Kitty uninstalled."
}

case "$ACTION" in
  deps)
    install_deps
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
  all)
    install_kitty
    check_font_installed
    configure_kitty
    ;;
  *)
    echo "Usage: $0 [deps|install|config|clean|all]"
    exit 1
    ;;
esac
