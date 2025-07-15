#!/bin/bash
set -e

# === Ensure proper download environment ===
if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  echo "❌ Neither curl nor wget is available for downloading."
  exit 1
fi

if [[ ! -f "${BASH_SOURCE[0]}" ]]; then
  tmp="/tmp/bootstrap.sh"
  echo "⚙️ Re-downloading script to $tmp for proper execution..."
  if command -v curl &>/dev/null; then
    curl -fsSL "https://.../bootstrap.sh" -o "$tmp"
  else
    wget -qO "$tmp" "https://.../bootstrap.sh"
  fi
  exec bash "$tmp" "$@"
fi

REPO_DIR="$HOME/.after-install"

# === Prevent running as root ===
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run as root. Use a normal user."
  exit 1
fi

# === Validate sudo with prompt ===
if ! sudo -v; then
  echo "❌ Unable to authenticate with sudo."
  echo "💡 Run this script in a terminal where you can enter your password."
  exit 1
fi

# === ensure_installed, repo clone/pull, etc. ===
ensure_installed() {
  pkg="$1"
  if ! command -v "$pkg" &>/dev/null; then
    echo "🔧 Installing $pkg..."
    sudo apt update
    sudo apt install -y "$pkg"
  else
    echo "✅ $pkg is already installed."
  fi
}

ensure_installed gum
ensure_installed curl
ensure_installed git

if [ -d "$REPO_DIR" ]; then
  echo "📦 Updating existing repo..."
  git -C "$REPO_DIR" pull
else
  echo "📥 Cloning after-install..."
  git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
fi

cd "$REPO_DIR"

"$REPO_DIR/modules/user-profile.sh" all

bash install.sh all
