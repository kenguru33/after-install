#!/bin/bash
set -x

MODULE_NAME="gnome-config"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_SOURCE="$REPO_DIR/wallpapers/background.jpg"
WALLPAPER_DEST="$HOME/Pictures/background.jpg"
ACTION="${1:-all}"

# === OS Detection ===
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  else
    echo "❌ Cannot detect OS. /etc/os-release missing."
    exit 1
  fi

  if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
    echo "⚠️ This module only supports Debian. Skipping."
    exit 0
  fi
}

# === Dependencies ===
DEPS=(libglib2.0-bin gsettings)
INSTALL_CMD="sudo apt install -y"
UPDATE_CMD="sudo apt update"

install_dependencies() {
  echo "🔧 Checking required dependencies..."
  $UPDATE_CMD

  for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo "📦 Installing $dep..."
      $INSTALL_CMD "$dep"
    else
      echo "✅ $dep is already installed."
    fi
  done
}

# === Wallpaper ===
install_wallpaper() {
  echo "📁 Checking for wallpaper in: $WALLPAPER_SOURCE"

  if [[ ! -f "$WALLPAPER_SOURCE" ]]; then
    echo "❌ Wallpaper not found: $WALLPAPER_SOURCE"
    exit 1
  fi

  echo "📥 Copying wallpaper to Pictures folder..."
  mkdir -p "$HOME/Pictures"
  cp "$WALLPAPER_SOURCE" "$WALLPAPER_DEST"
  echo "✅ Wallpaper copied to: $WALLPAPER_DEST"
}

reset_wallpaper() {
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background.picture-uri-dark

  if [[ -f "$WALLPAPER_DEST" ]]; then
    echo "🗑️  Removing copied wallpaper from Pictures..."
    rm -f "$WALLPAPER_DEST"
  fi
}

# === Appearance ===
apply_appearance_settings() {
  gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DEST"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DEST"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  #gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
  gsettings set org.gnome.desktop.wm.preferences button-layout ':close'
}

reset_appearance_settings() {
  gsettings reset org.gnome.desktop.interface color-scheme
  gsettings reset org.gnome.desktop.wm.preferences.button-layout
}

# === Keybindings + Workspaces ===
configure_workspace_keys() {
  echo "🎯 Setting up GNOME workspace configuration and keybindings..."

  # Static workspaces (disable dynamic)
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
  echo "🔢 Set static workspaces: 3"

  # Move window up/down
  #gsettings set org.gnome.desktop.wm.keybindings.move-to-workspace-up "['<Control><Alt>Up']"
  #gsettings set org.gnome.desktop.wm.keybindings.move-to-workspace-down "['<Control><Alt>Down']"

  echo "✅ GNOME keybindings set:"
  echo "   - Ctrl+Alt+←/→: switch (default)"
  echo "   - Ctrl+Alt+↑/↓: move window"
  echo "   - Ctrl+Alt+1..9: switch to workspace"
  echo "   - Ctrl+Alt+Shift+1..9: move window to workspace"
}

reset_workspace_keys() {
  echo "🧹 Resetting workspace keybindings..."

  gsettings reset org.gnome.desktop.wm.keybindings.move-to-workspace-up
  gsettings reset org.gnome.desktop.wm.keybindings.move-to-workspace-down

  for i in {1..9}; do
    gsettings reset "org.gnome.desktop.wm.keybindings.switch-to-workspace-$i"
    gsettings reset "org.gnome.desktop.wm.keybindings.move-to-workspace-$i"
  done

  echo "🔄 Re-enabling dynamic workspaces..."
  gsettings set org.gnome.mutter dynamic-workspaces true
}

# === Main Config and Clean ===
config_gnome() {
  apply_appearance_settings
  configure_workspace_keys
  echo "✅ GNOME configuration applied."
}

clean_config() {
  reset_wallpaper
  reset_appearance_settings
  reset_workspace_keys
  echo "✅ GNOME settings reset."
}

# === Help ===
show_help() {
  echo "Usage: $0 {all|deps|install|config|clean}"
  echo ""
  echo "  all      Run deps + install + config"
  echo "  deps     Install required tools"
  echo "  install  Copy wallpaper"
  echo "  config   Apply GNOME settings and keybindings"
  echo "  clean    Reset GNOME settings and remove wallpaper"
}

# === Entry Point ===
main() {
  detect_os

  case "$ACTION" in
  all)
    install_dependencies
    install_wallpaper
    config_gnome
    ;;
  deps)
    install_dependencies
    ;;
  install)
    install_wallpaper
    ;;
  config)
    config_gnome
    ;;
  clean)
    clean_config
    ;;
  *)
    show_help
    exit 1
    ;;
  esac
}

main
