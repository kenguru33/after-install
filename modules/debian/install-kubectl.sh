#!/bin/bash
set -e
trap 'echo "❌ kubectl install failed. Exiting." >&2' ERR

MODULE_NAME="kubectl"
ACTION="${1:-all}"
REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$REAL_USER")"
LOCAL_BIN="$HOME_DIR/.local/bin"
PLUGIN_DIR="$HOME_DIR/.zsh/plugins/kubectl"
CONFIG_DIR="$HOME_DIR/.zsh/config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/config/kubectl.zsh"
TARGET_FILE="$CONFIG_DIR/kubectl.zsh"
COMPLETION_FILE="$PLUGIN_DIR/kubectl.zsh"

# === Step: deps ===
deps() {
  echo "📦 Checking for curl..."

  if ! command -v curl >/dev/null; then
    echo "❌ curl is not installed. Please install it manually."
    exit 1
  fi
}

# === Step: install ===
install() {
  echo "⬇️ Installing latest kubectl to $LOCAL_BIN..."

  mkdir -p "$LOCAL_BIN"
  KUBECTL_URL="https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

  curl -fsSL "$KUBECTL_URL" -o "$LOCAL_BIN/kubectl"
  chmod +x "$LOCAL_BIN/kubectl"
  chown "$REAL_USER:$REAL_USER" "$LOCAL_BIN/kubectl"
  echo "✅ Installed kubectl → $LOCAL_BIN/kubectl"

  echo "📄 Generating kubectl completion..."
  mkdir -p "$PLUGIN_DIR"
  "$LOCAL_BIN/kubectl" completion zsh > "$COMPLETION_FILE"
  chown -R "$REAL_USER:$REAL_USER" "$PLUGIN_DIR"
  echo "✅ Created $COMPLETION_FILE"
}

# === Step: config ===
config() {
  echo "📝 Installing kubectl.zsh config from template..."

  mkdir -p "$CONFIG_DIR"
  cp "$TEMPLATE_FILE" "$TARGET_FILE"
  chown "$REAL_USER:$REAL_USER" "$TARGET_FILE"
  echo "✅ Installed $TARGET_FILE"
}

# === Step: clean ===
clean() {
  echo "🧹 Cleaning kubectl setup..."

  echo "❌ Removing kubectl binary"
  rm -f "$LOCAL_BIN/kubectl"

  echo "❌ Removing kubectl plugin dir"
  rm -rf "$PLUGIN_DIR"

  echo "❌ Removing kubectl.zsh config"
  rm -f "$TARGET_FILE"

  echo "✅ Clean complete."
}

# === Entry Point ===
case "$ACTION" in
  all)    deps; install; config ;;
  deps)   deps ;;
  install) install ;;
  config) config ;;
  clean)  clean ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
