#!/bin/bash
set -e

REPO_DIR="$HOME/.after-install"

# === Check that script is not run as root ===
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run this script as root."
  echo "💡 Run it as a regular user who has sudo access."
  exit 1
fi

# === Check if user has sudo privileges ===
if ! sudo -n true 2>/dev/null; then
  echo "❌ You must have sudo privileges to run this script."
  echo ""
  echo "💡 To add yourself to the sudo group (requires root):"
  echo "   su -c 'usermod -aG sudo $USER'"
  echo ""
  echo "🔁 Then log out and back in for the change to take effect."
  exit 1
fi

# === Function to ensure a package is installed ===
ensure_installed() {
  local pkg="$1"
  if ! command -v "$pkg" &>/dev/null; then
    echo "🔧 Installing $pkg..."
    sudo apt update
    sudo apt install -y "$pkg"
  else
    echo "✅ $pkg is already installed."
  fi
}

# === Ensure required tools ===
ensure_installed curl
ensure_installed git

# === Clone or update the repo ===
if [ -d "$REPO_DIR" ]; then
  echo "📦 Updating existing repo..."
  git -C "$REPO_DIR" pull
else
  echo "📥 Cloning after-install repo..."
  git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
fi

cd "$REPO_DIR"
bash install.sh all
