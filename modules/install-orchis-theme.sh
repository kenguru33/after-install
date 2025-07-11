#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${THEME_DIR:-orchis}"
THEME_COLOR="dark"
THEME_SHELL_COLOR="Dark"
THEME_BACKGROUND="background.jpg"

THEME_PATH="$SCRIPT_DIR/$THEME_DIR"
BACKGROUND_ORG_PATH="$THEME_PATH/$THEME_BACKGROUND"
BACKGROUND_DEST_DIR="$HOME/.local/share/backgrounds"
BACKGROUND_DEST_PATH="$BACKGROUND_DEST_DIR/${THEME_DIR}-${THEME_BACKGROUND}"

[[ -f "$THEME_PATH/${THEME_DIR}.sh" ]] && source "$THEME_PATH/${THEME_DIR}.sh"

install_theme_packages() {
  echo "📦 Installing required theme packages..."
  sudo apt update
  sudo apt install -y gnome-tweaks gnome-shell-extensions dconf-cli git
  echo "✅ Packages installed."
}

install_theme_assets() {
  echo "🎨 Installing Orchis GTK and Tela icon themes..."
  mkdir -p ~/.themes ~/.icons

  if [ ! -d /tmp/Orchis-theme ]; then
    git clone https://github.com/vinceliuice/Orchis-theme.git /tmp/Orchis-theme
  fi
  /tmp/Orchis-theme/install.sh --tweaks macos -l -c "$THEME_COLOR" -s standard

  if [ ! -d /tmp/Tela-icon-theme ]; then
    git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/Tela-icon-theme
  fi
  /tmp/Tela-icon-theme/install.sh -d ~/.icons

  echo "✅ Themes installed."
}

apply_theme_config() {
  echo "🎛️ Applying GNOME settings..."

  gsettings set org.gnome.desktop.interface gtk-theme "Orchis-$THEME_COLOR"
  gsettings set org.gnome.desktop.interface icon-theme "Tela-$THEME_COLOR"
  gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.wm.preferences theme "Orchis-$THEME_SHELL_COLOR"

  mkdir -p "$BACKGROUND_DEST_DIR"
  if [[ -f "$BACKGROUND_ORG_PATH" ]]; then
    cp -u "$BACKGROUND_ORG_PATH" "$BACKGROUND_DEST_PATH"
    gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_DEST_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_DEST_PATH"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
  else
    echo "⚠️ Background not found: $BACKGROUND_ORG_PATH"
  fi

  EXT_ID="user-theme@gnome-shell-extensions.gcampax.github.com"
  if gnome-extensions list | grep -q "$EXT_ID"; then
    echo "🔁 Enabling User Themes extension..."
    gnome-extensions enable "$EXT_ID" || true
    sleep 1
    gsettings set org.gnome.shell.extensions.user-theme name "Orchis-$THEME_SHELL_COLOR"
    echo "✅ Shell theme applied and extension enabled."
  else
    echo "❌ User Themes extension not found. Cannot apply shell theme."
  fi

  echo "✅ GNOME theme configuration complete."
}

clean_theme() {
  echo "🧹 Cleaning up themes..."
  rm -rf ~/.themes/Orchis* ~/.icons/Tela* "$BACKGROUND_DEST_PATH"
  echo "✅ Theme files removed. Please reset GNOME appearance manually if needed."
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install dependencies, themes, and apply settings"
  echo "  install  Install theme packages and assets only"
  echo "  config   Apply GTK, icon, shell theme and wallpaper"
  echo "  clean    Remove installed theme assets"
}

# === Main ===
case "$1" in
  all)
    install_theme_packages
    install_theme_assets
    apply_theme_config
    ;;
  install)
    install_theme_packages
    install_theme_assets
    ;;
  config)
    apply_theme_config
    ;;
  clean)
    clean_theme
    ;;
  *)
    show_help
    ;;
esac
