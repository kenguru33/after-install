#!/bin/bash
set -e

# === Ensure curl or wget is available ===
if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  echo "❌ Neither curl nor wget is available for downloading."
  exit 1
fi

# === Re-download self if not run as a file ===
if [[ ! -f "${BASH_SOURCE[0]}" ]]; then
  tmp="/tmp/bootstrap.sh"
  echo "⚙️ Re-downloading script to $tmp for proper execution..."
  if command -v curl &>/dev/null; then
    curl -fsSL "https://.../bootstrap.sh" -o "$tmp"
  else
    wget -qO "$tmp" "https://.../bootstrap.sh"
  fi
  chmod +x "$tmp"
  exec bash "$tmp" "$@"
fi

REPO_DIR="$HOME/.after-install"

# === Prevent root execution ===
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run as root. Use a normal user."
  exit 1
fi

# === Validate sudo access ===
REAL_USER="$(logname 2>/dev/null || echo "$USER")"

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

# === Ensure curl and git are installed ===
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

# === Ensure gum is installed ===
GUM_VERSION="0.14.3"
if ! command -v gum &>/dev/null; then
  echo "✨ Installing gum..."
  wget -qO /tmp/gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
  sudo apt-get install -y --allow-downgrades /tmp/gum.deb
  rm /tmp/gum.deb
else
  echo "✅ gum is already installed."
fi

# === Clone or update the repo ===
if [ -d "$REPO_DIR" ]; then
  echo "📦 Updating existing repo at $REPO_DIR..."
  git -C "$REPO_DIR" pull
else
  echo "📥 Cloning after-install repo to $REPO_DIR..."
  git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
fi

# === Change into repo directory ===
cd "$REPO_DIR"

# === Check for install.sh ===
if [[ ! -f "install.sh" ]]; then
  echo "❌ install.sh not found in $REPO_DIR"
  echo "📂 Contents:"
  ls -la "$REPO_DIR"
  exit 1
fi

# === Run main installer ===
echo "✅ Bootstrap completed. Running install.sh..."
bash install.sh all
