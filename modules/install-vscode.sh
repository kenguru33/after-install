#!/bin/bash
set -e

# === Functions ===

install_dependencies() {
  echo "🔧 Installing required dependencies..."
  sudo apt update
  sudo apt install -y curl gpg apt-transport-https

  echo "🔐 Adding Microsoft GPG key..."
  curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg > /dev/null

  echo "📦 Adding VS Code apt repository..."
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

  sudo apt update
}

install_vscode() {
  echo "📦 Installing VS Code..."
  sudo DEBIAN_FRONTEND=noninteractive apt install -y code
}

cleanup() {
  echo "🧹 Cleaning up..."
  sudo rm -f /etc/apt/sources.list.d/vscode.list
  sudo rm -f /usr/share/keyrings/vscode.gpg
}

show_help() {
  echo "Usage: $0 [all|deps|install|clean]"
  echo ""
  echo "  all       Run full installation process"
  echo "  deps      Install dependencies and add repo"
  echo "  install   Install VS Code from repo"
  echo "  clean     Remove repo and key (optional cleanup)"
}

# === Entry Point ===

case "$1" in
  all)
    install_dependencies
    install_vscode
    ;;
  deps)
    install_dependencies
    ;;
  install)
    install_vscode
    ;;
  clean)
    cleanup
    ;;
  *)
    show_help
    ;;
esac
