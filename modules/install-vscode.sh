#!/bin/bash
set -e

# === Functions ===

install_dependencies() {
  echo "🔧 Installing required dependencies..."
  sudo apt update
  sudo apt install -y curl gpg
}

download_vscode() {
  echo "⬇️ Downloading latest VS Code .deb package..."
  curl -L -o /tmp/code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
}

install_vscode() {
  echo "📦 Installing VS Code..."
  sudo apt install -y /tmp/code.deb
}

cleanup() {
  echo "🧹 Cleaning up..."
  rm -f /tmp/code.deb
}

show_help() {
  echo "Usage: $0 [all|deps|download|install|clean]"
  echo ""
  echo "  all       Run full installation process"
  echo "  deps      Install required dependencies"
  echo "  download  Download the VS Code .deb package"
  echo "  install   Install the downloaded package"
  echo "  clean     Remove temporary files"
}

# === Entry Point ===

case "$1" in
  all)
    install_dependencies
    download_vscode
    install_vscode
    cleanup
    ;;
  deps)
    install_dependencies
    ;;
  download)
    download_vscode
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

