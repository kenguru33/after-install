#!/bin/bash
set -e

MODULE_NAME="google-chrome"
ACTION="${1:-all}"
DEB_PATH="/tmp/google-chrome-stable.deb"
RPM_PATH="/tmp/google-chrome-stable.rpm"
LOCK_FILE="/var/lib/rpm/.rpm.lock"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect operating system."
  exit 1
fi

# === Dependencies ===
DEPS_DEBIAN=(curl wget gnupg apt-transport-https)
DEPS_FEDORA=(curl wget gnupg2)

wait_for_rpm_lock() {
  if [[ "$OS_ID" == "fedora" ]]; then
    echo "⏳ Waiting for RPM lock to be released..."
    while fuser "$LOCK_FILE" &>/dev/null; do
      sleep 1
    done
    echo "🔓 RPM lock released. Continuing..."
  fi
}

install_deps() {
  echo "📦 Installing dependencies for $OS_ID..."
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt update
    sudo apt install -y "${DEPS_DEBIAN[@]}"
  elif [[ "$OS_ID" == "fedora" ]]; then
    wait_for_rpm_lock
    sudo dnf install -y "${DEPS_FEDORA[@]}"
  else
    echo "❌ Unsupported OS: $OS_ID"
    exit 1
  fi
}

install_chrome() {
  echo "⬇️  Downloading Google Chrome for $OS_ID..."

  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    curl -fsSL -o "$DEB_PATH" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    echo "📦 Installing Google Chrome .deb package..."
    sudo apt install -y "$DEB_PATH"
  elif [[ "$OS_ID" == "fedora" ]]; then
    wait_for_rpm_lock
    curl -fsSL -o "$RPM_PATH" https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

    echo "🔑 Importing Google Linux GPG key..."
    sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub

    echo "📦 Installing Google Chrome .rpm package..."
    sudo dnf install -y "$RPM_PATH"
  else
    echo "❌ Unsupported OS: $OS_ID"
    exit 1
  fi

  echo "✅ Google Chrome installed."
}

config_chrome() {
  echo "⚙️  No additional config needed for Chrome. Skipping..."
}

clean_chrome() {
  echo "🧹 Uninstalling Google Chrome..."

  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt remove -y google-chrome-stable || true
    sudo apt autoremove -y
    rm -f "$DEB_PATH"
  elif [[ "$OS_ID" == "fedora" ]]; then
    wait_for_rpm_lock
    sudo dnf remove -y google-chrome-stable || true
    rm -f "$RPM_PATH"
  else
    echo "❌ Unsupported OS: $OS_ID"
    exit 1
  fi

  echo "✅ Chrome uninstalled and cleaned."
}

# === Main entry point ===
case "$ACTION" in
  deps)
    install_deps
    ;;
  install)
    install_chrome
    ;;
  config)
    config_chrome
    ;;
  clean)
    clean_chrome
    ;;
  all)
    install_deps
    install_chrome
    config_chrome
    ;;
  *)
    echo "Usage: $0 {deps|install|config|clean|all}"
    exit 1
    ;;
esac
