#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_NAME="bootstrap.sh"
REPO_DIR="$HOME/.after-install"
REAL_USER="$(logname 2>/dev/null || echo "$USER")"
ACTION="all"
VERBOSE=0
GUM_VERSION="0.14.3"

# === Parse arguments ===
for arg in "$@"; do
  case "$arg" in
    -v|--verbose)
      VERBOSE=1
      ;;
    all|deps|install)
      ACTION="$arg"
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo "Usage: $SCRIPT_NAME [all|deps|install] [--verbose]"
      exit 1
      ;;
  esac
done

# === Verbose helper ===
run() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

if [[ "$VERBOSE" -eq 1 ]]; then
  echo "🔍 Verbose mode enabled"
fi

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

clear

# === DEPS: install essential tools ===
install_dependencies() {
  echo "📦 Installing dependencies for $OS_ID..."

  case "$OS_ID" in
    debian|ubuntu)
      run sudo apt update
      run sudo apt install -y curl wget git figlet gnupg2 apt-transport-https

      if ! command -v gum &>/dev/null; then
        run wget -O /tmp/gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
        run sudo apt install -y /tmp/gum.deb
        rm -f /tmp/gum.deb
      fi
      ;;
    fedora)
      run sudo dnf install -y curl wget git figlet gnupg2 dnf-plugins-core

      if ! command -v gum &>/dev/null; then
        run sudo dnf install -y gum
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
    run git -C "$REPO_DIR" pull
  else
    run git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
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
  all)
    install_dependencies
    install_repo
    run_installer
    ;;
esac
