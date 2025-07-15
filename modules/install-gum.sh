#!/bin/bash
set -e

MODULE_NAME="gum"
ACTION="${1:-all}"
GUM_VERSION="0.14.3"
GUM_MIN_VERSION="0.11.0"
DEB_FILE="gum_${GUM_VERSION}_amd64.deb"
DOWNLOAD_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${DEB_FILE}"

# === Version utilities ===
get_installed_version() {
  if ! command -v gum &>/dev/null; then
    echo "0.0.0"
    return
  fi

  gum --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0"
}

version_ge() {
  [ "$(printf "%s\n$1\n$2" | sort -V | head -n1)" = "$2" ]
}

# === Installer ===
install_gum() {
  echo "📦 Downloading gum v$GUM_VERSION..."
  wget -qO "$DEB_FILE" "$DOWNLOAD_URL"

  echo "📦 Installing gum via dpkg..."
  sudo apt-get install -y --allow-downgrades "./$DEB_FILE" &>/dev/null

  rm -f "$DEB_FILE"
  echo "✅ gum v$GUM_VERSION installed"
}

check_and_install_gum() {
  INSTALLED_VERSION=$(get_installed_version)

  if [[ "$INSTALLED_VERSION" == "0.0.0" ]]; then
    echo "🔧 gum not found. Installing..."
    install_gum
  elif ! version_ge "$INSTALLED_VERSION" "$GUM_MIN_VERSION"; then
    echo "🔧 gum version $INSTALLED_VERSION is too old. Upgrading..."
    install_gum
  else
    echo "✅ gum $INSTALLED_VERSION is OK"
  fi
}

clean_gum() {
  echo "🧹 Removing gum..."
  sudo apt-get remove -y gum
}

# === Dispatcher ===
case "$ACTION" in
  install|all)
    check_and_install_gum
    ;;
  clean)
    clean_gum
    ;;
  *)
    echo "Usage: $0 [install|clean|all]"
    exit 1
    ;;
esac
