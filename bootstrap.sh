#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_NAME="bootstrap.sh"
REPO_URL="https://github.com/kenguru33/after-install"
REPO_DIR="$HOME/.after-install"
REAL_USER="$(logname 2>/dev/null || echo "$USER")"
ACTION="${1:-all}"
VERBOSE=0
GUM_VERSION="0.14.3"

# === Parse arguments ===
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
    all|deps|install|config|clean) ACTION="$arg" ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo "Usage: $SCRIPT_NAME [all|deps|install|config|clean] [--verbose]"
      exit 1
      ;;
  esac
done

# === Detect OS and distribution ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Cannot detect OS. /etc/os-release is missing."
  exit 1
fi

# === Prevent root execution ===
if [[ "$EUID" -eq 0 ]]; then
  echo "❌ Do not run as root. Use a regular user."
  exit 1
fi

# === Ensure sudo access ===
if ! sudo -v; then
  echo "❌ This script requires sudo access."
  exit 1
fi

# === Clone or update repo ===
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "📥 Cloning repo to $REPO_DIR..."
  git clone --depth=1 "$REPO_URL" "$REPO_DIR"
else
  echo "🔄 Updating repo in $REPO_DIR..."
  git -C "$REPO_DIR" pull --ff-only
fi

# === Source helpers ===
source "$REPO_DIR/common/required.sh"
ensure_git_installed
ensure_gum_installed "$GUM_VERSION"

# === Show banner ===
if [[ -x "$REPO_DIR/common/banner.sh" ]]; then
  ID="$OS_ID" "$REPO_DIR/common/banner.sh"
fi

# === Dispatch to distro-specific installer ===
cd "$REPO_DIR"

case "$OS_ID" in
  debian|ubuntu)
    exec "$REPO_DIR/debian/install.sh" "$ACTION" "${VERBOSE:+--verbose}"
    ;;
  fedora)
    exec "$REPO_DIR/fedora/install.sh" "$ACTION" "${VERBOSE:+--verbose}"
    ;;
  *)
    echo "❌ Unsupported distribution: $OS_ID"
    exit 1
    ;;
esac
