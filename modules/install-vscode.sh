#!/bin/bash
set -e
trap 'echo "ERROR ❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="vscode"
ACTION="${1:-all}"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

# === Step 1: Dependencies (optional) ===
install_dependencies() {
  echo "🔧 Installing required tools..."

  if command -v apt &>/dev/null; then
    sudo apt update -qq
    sudo apt install -y curl
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y curl
  else
    echo "❌ Unsupported package manager."
    exit 1
  fi

  echo "✅ Dependencies installed."
}

# === Step 2: Install ===
install_vscode() {
  echo "🖥️ Installing VS Code..."

  if command -v code >/dev/null 2>&1; then
    echo "✅ VS Code is already installed."
    return
  fi

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    curl -fsSL https://update.code.visualstudio.com/latest/linux-deb-x64/stable -o /tmp/vscode.deb
    sudo apt install -y /tmp/vscode.deb
  elif [[ "$ID" == "fedora" || "$ID_LIKE" == *"fedora"* ]]; then
    curl -fsSL https://update.code.visualstudio.com/latest/linux-rpm-x64/stable -o /tmp/vscode.rpm
    sudo dnf install -y /tmp/vscode.rpm
  else
    echo "❌ Unsupported OS: $ID"
    exit 1
  fi

  echo "✅ VS Code installed."
}

# === Step 3: Clean ===
cleanup() {
  echo "🧹 Cleaning up VS Code..."

  sudo rm -f /tmp/vscode.deb /tmp/vscode.rpm

  if command -v code &>/dev/null; then
    if command -v apt &>/dev/null; then
      sudo apt remove --purge -y code
    elif command -v dnf &>/dev/null; then
      sudo dnf remove -y code
    fi
  fi

  echo "✅ Cleanup complete."
}

# === Help ===
show_help() {
  echo "Usage: $0 [all|deps|install|clean]"
  echo ""
  echo "  all       Install dependencies and VS Code"
  echo "  deps      Install curl (if missing)"
  echo "  install   Download and install VS Code"
  echo "  clean     Remove VS Code and any temp files"
}

# === Entry Point ===
case "$ACTION" in
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
