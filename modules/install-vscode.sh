#!/bin/bash
set -e
trap 'echo "ERROR ❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="vscode"
ACTION="${1:-all}"

# === Config ===
DEPS_DEBIAN=("curl" "gnupg" "apt-transport-https")
DEPS_FEDORA=("curl" "gnupg")

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

install_dependencies() {
  echo "🔧 Installing dependencies and adding Microsoft repo..."

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt update -qq
    sudo apt install -y "${DEPS_DEBIAN[@]}"

    echo "🔐 Adding Microsoft GPG key..."
    sudo install -d /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor | \
      sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null

    echo "📦 Adding VS Code APT repo..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt update -qq

  elif [[ "$ID" == "fedora" ]]; then
    sudo dnf install -y "${DEPS_FEDORA[@]}"

    echo "🔐 Adding Microsoft GPG key..."
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | \
      sudo tee /etc/pki/rpm-gpg/Microsoft.asc > /dev/null

    echo "📦 Adding VS Code DNF repo..."
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/Microsoft.asc
EOF

    sudo dnf check-update || true

  else
    echo "❌ Unsupported OS: $ID"
    exit 1
  fi
}

install_vscode() {
  echo "🖥️ Installing VS Code..."

  if command -v code >/dev/null 2>&1; then
    echo "✅ VS Code is already installed."
    return
  fi

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt install -y code
  elif [[ "$ID" == "fedora" ]]; then
    sudo dnf install -y code
  else
    echo "❌ Unsupported OS: $ID"
    exit 1
  fi
}

cleanup() {
  echo "🧹 Cleaning up VS Code..."

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt remove --purge -y code
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /etc/apt/keyrings/microsoft.gpg
    echo "🗑️ Removed APT repo and GPG key."
  elif [[ "$ID" == "fedora" ]]; then
    sudo dnf remove -y code
    sudo rm -f /etc/yum.repos.d/vscode.repo
    sudo rm -f /etc/pki/rpm-gpg/Microsoft.asc
    echo "🗑️ Removed DNF repo and GPG key."
  fi
}

show_help() {
  echo "Usage: $0 [all|deps|install|clean]"
  echo ""
  echo "  all       Run full VS Code setup (deps + install)"
  echo "  deps      Install dependencies and add Microsoft repo"
  echo "  install   Install the VS Code package"
  echo "  clean     Remove repo, GPG key, and uninstall VS Code"
}

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
