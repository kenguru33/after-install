#!/bin/bash
set -e

# === Ensure proper download environment ===
if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  echo "❌ Neither curl nor wget is available for downloading."
  exit 1
fi

# === Re-download self if not run from file ===
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

if ! sudo -v >/dev/null 2>&1; then
  echo "🚫 User '$REAL_USER' does not have sudo privileges or authentication failed."
  echo ""
  echo "🛠️  To give this user sudo access:"
  echo "   1. Switch to root:         su -"
  echo "   2. Run this command:       usermod -aG sudo $REAL_USER"
  echo "   3. Log out and log in again (or reboot)"
  echo ""
  echo "📄 Ensure $REAL_USER is listed in /etc/sudoers (directly or via group)."
  exit 1
fi

# === Ensure key packages (curl + git) for repo cloning ===
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

ensure_installed curl
ensure_installed git

# === Clone repo if not already ===
if [ -d "$REPO_DIR" ]; then
  echo "📦 Updating existing repo..."
  git -C "$REPO_DIR" pull
else
  echo "📥 Cloning after-install..."
  git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
fi

# === Now we can safely call gum module ===
"$REPO_DIR/modules/install-gum.sh" install

# === Clear screen for next prompt ===
clear

gum format --theme=dark <<EOF
# 🛠️ After Install

A clean and modular bootstrap framework  
for configuring your terminal and desktop environments.
EOF

cd "$REPO_DIR"

# === Ask user for name/email
"$REPO_DIR/modules/user-profile.sh" all

# === Run main installer
bash install.sh all
