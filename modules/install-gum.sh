#!/bin/bash
set -e

MODULE_NAME="gum"
ACTION="${1:-all}"
INSTALL_PATH="/usr/local/bin/gum"
GUM_MIN_VERSION="0.11.0"

# === Version utilities ===
get_installed_version() {
  if ! command -v gum &>/dev/null; then
    echo "0.0.0"
    return
  fi

  gum --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0"
}

version_ge() {
  # returns true if $1 >= $2
  [ "$(printf "%s\n$1\n$2" | sort -V | head -n1)" = "$2" ]
}

# === Installer ===
install_gum() {
  VERSION="0.14.1"
  ARCH=$(uname -m)
  ARCH="${ARCH/x86_64/amd64}"
  TMP_DIR=$(mktemp -d)

  echo "📦 Downloading gum v$VERSION..."
  curl -fsSL "https://github.com/charmbracelet/gum/releases/download/v${VERSION}/gum_${VERSION}_linux_${ARCH}.tar.gz" \
    | tar -xz -C "$TMP_DIR" &>/dev/null

  echo "📦 Installing gum to $INSTALL_PATH..."
  sudo mv "$TMP_DIR/gum" "$INSTALL_PATH"
  sudo chmod +x "$INSTALL_PATH"
  rm -rf "$TMP_DIR"

  echo "✅ gum v$VERSION installed"
}

# === Install entrypoint ===
check_and_install_gum() {
  INSTALLED_VERSION=$(get_installed_version)

  if [[ "$INSTALLED_VERSION" == "0.0.0" ]]; then
    echo "🔧 gum not found. Installing..."
    install_gum
  elif ! version_ge "$INSTALLED_VERSION" "$GUM_MIN_VERSION"; then
    echo "🔧 gum version $INSTALLED_VERSION is too old. Upgrading..."
    install_gum
  else
    echo "✅ gum $INSTALLED_VERSION meets requirements"
  fi
}

# === Cleaner ===
clean_gum() {
  echo "🧹 Removing gum from $INSTALL_PATH"
  sudo rm -f "$INSTALL_PATH"
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
