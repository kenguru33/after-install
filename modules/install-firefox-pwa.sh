#!/bin/bash
set -e

MODULE_NAME="firefoxpwa"
ACTION="${1:-all}"

install_firefoxpwa() {
  echo "📦 Installing FirefoxPWA..."

  # Ensure required dependencies
  sudo apt update
  sudo apt install -y debian-archive-keyring curl gpg apt-transport-https

  # Add GPG key and repo
  echo "🔑 Importing GPG key..."
  curl -fsSL https://packagecloud.io/filips/FirefoxPWA/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/firefoxpwa-keyring.gpg > /dev/null

  echo "📁 Adding APT source..."
  echo "deb [signed-by=/usr/share/keyrings/firefoxpwa-keyring.gpg] https://packagecloud.io/filips/FirefoxPWA/any any main" | sudo tee /etc/apt/sources.list.d/firefoxpwa.list > /dev/null

  # Install the package
  echo "🔄 Updating repositories..."
  sudo apt update

  echo "📦 Installing firefoxpwa package..."
  sudo apt install -y firefoxpwa

  echo "✅ FirefoxPWA installed."
}

config_firefoxpwa() {
  echo "⚙️ No additional configuration needed for FirefoxPWA."
}

clean_firefoxpwa() {
  echo "🧹 Cleaning FirefoxPWA setup..."

  sudo rm -f /usr/share/keyrings/firefoxpwa-keyring.gpg
  sudo rm -f /etc/apt/sources.list.d/firefoxpwa.list
  sudo apt purge -y firefoxpwa
  sudo apt autoremove -y

  echo "✅ FirefoxPWA removed."
}

case "$ACTION" in
  install) install_firefoxpwa ;;
  config) config_firefoxpwa ;;
  clean) clean_firefoxpwa ;;
  all)
    install_firefoxpwa
    config_firefoxpwa
    ;;
  *)
    echo "Usage: $0 {install|config|clean|all}"
    exit 1
    ;;
esac
