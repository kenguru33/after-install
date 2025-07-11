#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

FONT_NAME="Hack Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
FONT_ZIP="/tmp/Hack.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip"

install_fonts() {
  echo "🔤 Installing $FONT_NAME..."

  if fc-list | grep -qi "Hack Nerd Font"; then
    echo "✅ $FONT_NAME already installed. Skipping."
    return
  fi

  mkdir -p "$FONT_DIR"
  wget -qO "$FONT_ZIP" "$FONT_URL"
  unzip -o "$FONT_ZIP" -d "$FONT_DIR"
  rm -f "$FONT_ZIP"
  fc-cache -fv > /dev/null

  echo "✅ $FONT_NAME installed and font cache refreshed."
}

configure_fonts() {
  echo "ℹ️ No configuration needed for $FONT_NAME."
}

clean_fonts() {
  echo "🧹 Removing $FONT_NAME..."
  rm -f "$FONT_DIR"/*Hack*
  fc-cache -fv > /dev/null
  echo "✅ Fonts removed and cache refreshed."
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install font (same as install)"
  echo "  install  Download and install $FONT_NAME"
  echo "  config   No-op (kept for pattern consistency)"
  echo "  clean    Remove font and refresh font cache"
}

case "$1" in
  all | install)
    install_fonts
    ;;
  config)
    configure_fonts
    ;;
  clean)
    clean_fonts
    ;;
  *)
    show_help
    ;;
esac
