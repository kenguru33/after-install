#!/bin/bash
set -e

MODULE_NAME="google-chrome"
ACTION="${1:-all}"
DEB_PATH="/tmp/google-chrome-stable.deb"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect operating system."
  exit 1
fi

if [[ "$OS_ID" != "debian" && "$OS_ID" != "ubuntu" ]]; then
  echo "❌ This script only supports Debian or Ubuntu."
  exit 1
fi

# === Dependencies ===
DEPS=(curl wget gnupg apt-transport-https)

install_deps() {
  echo "📦 Installing dependencies..."
  sudo apt update
  sudo apt install -y "${DEPS[@]}"
}

install_chrome() {
  echo "⬇️  Downloading Google Chrome .deb..."
  curl -fsSL -o "$DEB_PATH" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  echo "📦 Installing Google Chrome..."
  sudo apt install -y "$DEB_PATH"

  echo "✅ Google Chrome installed."
}

config_chrome() {
  echo "⚙️  Configuring Chrome launch flags..."

  # Detect NVIDIA (proprietary driver)
  USE_VULKAN=true
  if lspci | grep -i nvidia &>/dev/null; then
    echo "⚠️  NVIDIA GPU detected — Vulkan will be skipped for safety."
    USE_VULKAN=false
  fi

  mkdir -p ~/.config
  {
    echo "--ozone-platform=wayland"
    if [[ "$USE_VULKAN" == true ]]; then
      echo "--enable-features=Vulkan"
    fi
  } > ~/.config/chrome-flags.conf

  echo "✅ ~/.config/chrome-flags.conf created with safe flags."

  echo "🌐 Setting Chrome as default browser..."
  xdg-settings set default-web-browser google-chrome.desktop || true

  if command -v update-alternatives &>/dev/null; then
    sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/google-chrome-stable 200
    sudo update-alternatives --set x-www-browser /usr/bin/google-chrome-stable
  fi
}

clean_chrome() {
  echo "🧹 Uninstalling Google Chrome..."
  sudo apt remove -y google-chrome-stable || true
  sudo apt autoremove -y
  rm -f "$DEB_PATH"
  rm -f ~/.config/chrome-flags.conf
  echo "✅ Chrome uninstalled and cleaned."
}

# === Main entry point ===
case "$ACTION" in
  deps)
    install_deps
    ;;
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
    install_deps
    install_chrome
    config_chrome
    ;;
  *)
    echo "Usage: $0 {deps|install|config|clean|all}"
    exit 1
    ;;
esac
