#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_NAME="bootstrap.sh"
REPO_DIR="$HOME/.after-install"
REAL_USER="$(logname 2>/dev/null || echo "$USER")"
ACTION="${1:-all}"
GUM_VERSION="0.14.3"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect OS."
  exit 1
fi

# === Prevent root execution ===
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run as root. Use a normal user."
  exit 1
fi

# === Validate sudo access ===
if ! sudo -v >/dev/null 2>&1; then
  echo "🚫 User '$REAL_USER' does not have sudo privileges or authentication failed."
  echo ""
  echo "🛠️  To give this user sudo access:"
  echo "   1. Switch to root:         su -"
  echo "   2. Run this command:       usermod -aG sudo $REAL_USER"
  echo "   3. Log out and log in again (or reboot)"
  exit 1
fi

# === Re-download self if not run as a file ===
if [[ ! -f "${BASH_SOURCE[0]}" ]]; then
  tmp="/tmp/bootstrap.sh"
  echo "⚙️ Re-downloading bootstrap script..."
  if command -v curl &>/dev/null; then
    curl -fsSL "https://raw.githubusercontent.com/kenguru33/after-install/main/bootstrap.sh" -o "$tmp"
  else
    wget -qO "$tmp" "https://raw.githubusercontent.com/kenguru33/after-install/main/bootstrap.sh"
  fi
  chmod +x "$tmp"
  clear
  exec bash "$tmp" "$@"
fi

clear

# === DEPS: install essential tools ===
install_dependencies() {
  echo "📦 Installing dependencies for $OS_ID..."

  case "$OS_ID" in
    debian|ubuntu)
      sudo apt update -qq
      sudo apt install -y curl wget git figlet gnupg2 apt-transport-https

      if ! command -v gum &>/dev/null; then
        wget -qO /tmp/gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
        sudo apt install -y /tmp/gum.deb
        rm -f /tmp/gum.deb
      fi
      ;;
    fedora)
      sudo dnf install -y curl wget git figlet gnupg2 dnf-plugins-core

      if ! command -v gum &>/dev/null; then
        #curl -fsSL -o /tmp/gum.rpm "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_x86_64.rpm"
        #sudo dnf install -y /tmp/gum.rpm
        #rm -f /tmp/gum.rpm
        dnf install -y gum
      fi
      ;;
    *)
      echo "❌ Unsupported OS: $OS_ID"
      exit 1
      ;;
  esac

  echo "✅ Dependencies installed."
}

# === INSTALL: clone or update repo ===
install_repo() {
  echo "📥 Cloning or updating after-install repo..."

  if [[ -d "$REPO_DIR" ]]; then
    git -C "$REPO_DIR" pull --quiet
  else
    git clone --quiet https://github.com/kenguru33/after-install.git "$REPO_DIR"
  fi
}

# === RUN: launch installer ===
run_installer() {
  cd "$REPO_DIR"

  if [[ ! -f "install.sh" ]]; then
    echo "❌ install.sh not found in $REPO_DIR"
    ls -la "$REPO_DIR"
    exit 1
  fi

  echo "🚀 Starting install.sh..."
  bash install.sh all
}

# === Entry Point ===
case "$ACTION" in
  deps)
    install_dependencies
    ;;
  install)
    install_repo
    run_installer
    ;;
  all|"")
    install_dependencies
    install_repo
    run_installer
    ;;
  *)
    echo "Usage: $SCRIPT_NAME [all|deps|install]"
    exit 1
    ;;
esac
