#!/bin/bash
set -e

# === Config ===
DEPS=("curl" "gpg")

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

# === Step 1: Install dependencies and add Microsoft repo ===
install_dependencies() {
  echo "🔧 Installing required dependencies..."

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt update -qq
    for dep in "${DEPS[@]}"; do
      if ! dpkg -l | grep -qw "$dep"; then
        echo "📦 Installing $dep..."
        sudo apt install -y "$dep"
      else
        echo "✅ $dep is already installed."
      fi
    done

    echo "🔐 Adding Microsoft GPG key..."
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor | \
      sudo tee /usr/share/keyrings/vscode.gpg > /dev/null

    echo "📦 Adding VS Code APT repo..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt update -qq

  elif [[ "$ID" == "fedora" ]]; then
    for dep in "${DEPS[@]}"; do
      if ! rpm -q "$dep" &>/dev/null; then
        echo "📦 Installing $dep..."
        sudo dnf install -y "$dep"
      else
        echo "✅ $dep is already installed."
      fi
    done

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

# === Step 2: Install VS Code ===
install_vscode() {
  echo "🖥️ Installing VS Code..."

  if command -v code >/dev/null 2>&1; then
    echo "✅ VS Code is already installed."
  else
    if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
      sudo apt install -y code
    elif [[ "$ID" == "fedora" ]]; then
      sudo dnf install -y code
    else
      echo "❌ Unsupported OS: $ID"
      exit 1
    fi
  fi
}

# === Step 3: Apply minimal config (optional settings only) ===
configure_vscode() {
  echo "⚙️ Configuring VS Code settings..."

  mkdir -p "$HOME/.config/Code/User"
  cat > "$HOME/.config/Code/User/settings.json" <<EOF
{
  "editor.tabSize": 2,
  "editor.formatOnSave": true,
  "files.autoSave": "onFocusChange"
}
EOF

  echo "✅ VS Code configured."
}

# === Step 4: Cleanup ===
cleanup() {
  echo "🧹 Cleaning up..."

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /usr/share/keyrings/vscode.gpg
    echo "🗑️ Removed APT repo and GPG key."
  elif [[ "$ID" == "fedora" ]]; then
    sudo rm -f /etc/yum.repos.d/vscode.repo
    sudo rm -f /etc/pki/rpm-gpg/Microsoft.asc
    echo "🗑️ Removed DNF repo and GPG key."
  fi

  echo "✅ Cleanup complete."
}

# === Help ===
show_help() {
  echo "Usage: $0 [all|deps|install|config|clean]"
  echo ""
  echo "  all       Run full VS Code setup (deps + install + config)"
  echo "  deps      Install dependencies and add Microsoft repo"
  echo "  install   Install the VS Code package"
  echo "  config    Apply basic settings (no extensions)"
  echo "  clean     Remove VS Code repo and GPG key"
}

# === Entry Point ===
case "$1" in
  all)
    install_dependencies
    install_vscode
    configure_vscode
    ;;
  deps)
    install_dependencies
    ;;
  install)
    install_vscode
    ;;
  config)
    configure_vscode
    ;;
  clean)
    cleanup
    ;;
  *)
    show_help
    ;;
esac
