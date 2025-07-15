#!/bin/bash
set -e

MODULE_NAME="google-chrome"
DEB_PATH="/tmp/google-chrome-stable.deb"
ACTION="${1:-all}"

install_chrome() {
  echo "⬇️  Downloading Google Chrome .deb package..."
  curl -fsSL -o "$DEB_PATH" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  echo "📦 Installing Google Chrome..."
  sudo apt update
  sudo apt install -y "$DEB_PATH"

  echo "✅ Google Chrome installed."
}

config_chrome() {
  echo "⚙️  No additional config needed for Chrome. Skipping..."
}

clean_chrome() {
  echo "🧹 Uninstalling Google Chrome..."
  sudo apt remove -y google-chrome-stable
  sudo apt autoremove -y
  rm -f "$DEB_PATH"
  echo "✅ Chrome uninstalled and temporary files cleaned up."
}

# === Entry point ===
case "$ACTION" in
  install)
    install_chrome
    ;;
  config)
    config_chrome
    ;;
  clean)
    clean_chrome
    ;;
  all)
    install_chrome
    config_chrome
    ;;
  *)
    echo "Usage: $0 {install|config|clean|all}"
    exit 1
    ;;
esac
