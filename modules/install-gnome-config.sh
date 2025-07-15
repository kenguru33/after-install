#!/bin/bash
set -e

MODULE_NAME="gnome-config"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_SOURCE="$REPO_DIR/wallpapers/background.jpg"
WALLPAPER_DEST="$HOME/Pictures/background.jpg"
ACTION="${1:-all}"

install_config() {
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

config_gnome() {
  echo "🎨 Configuring GNOME settings..."

  # Set wallpaper (dark and light)
  gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DEST"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DEST"

  # Enable dark mode
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  # Set control buttons layout
  gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

  echo "✅ GNOME configuration applied."
}

clean_config() {
  echo "🧹 Resetting GNOME settings..."

  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background.picture-uri-dark
  gsettings reset org.gnome.desktop.interface color-scheme
  gsettings reset org.gnome.desktop.wm.preferences button-layout

  if [[ -f "$WALLPAPER_DEST" ]]; then
    echo "🗑️  Removing copied wallpaper from Pictures..."
    rm -f "$WALLPAPER_DEST"
  fi

  echo "✅ GNOME settings reset."
}

# === Entry point ===
case "$ACTION" in
  install)
    install_config
    ;;
  config)
    config_gnome
    ;;
  clean)
    clean_config
    ;;
  all)
    install_config
    config_gnome
    ;;
  *)
    echo "Usage: $0 {install|config|clean|all}"
    exit 1
    ;;
esac
