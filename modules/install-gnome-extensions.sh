#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

# Ensure pipx-installed gext is available
export PATH="$HOME/.local/bin:$PATH"

EXTENSIONS=(
  user-theme@gnome-shell-extensions.gcampax.github.com
  useless-gaps@pimsnel.com
  rounded-window-corners@fxgn
)

install_dependencies() {
  echo "📦 Installing dependencies..."
  sudo apt update
  sudo apt install -y gnome-shell-extension-manager pipx jq wget gnome-shell-extensions dconf-cli

  echo "📦 Installing gext..."
  pipx install gnome-extensions-cli --system-site-packages || true
}

install_extensions() {
  echo "🧩 Installing GNOME extensions using gext..."
  for ext in "${EXTENSIONS[@]}"; do
    gext install "$ext"
  done
}

compile_schemas() {
  echo "🔧 Compiling schemas for extensions..."
  for ext in "${EXTENSIONS[@]}"; do
    SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$ext/schemas"
    if [ -d "$SCHEMA_DIR" ]; then
      echo "📄 Compiling schemas for $ext"
      glib-compile-schemas "$SCHEMA_DIR"
    fi
  done
}

configure_extensions() {
  echo "🛠️ Configuring extensions..."
  # No specific gsettings in this reduced version, but structure kept
}

enable_extensions() {
  echo "✅ Enabling extensions..."
  for ext in "${EXTENSIONS[@]}"; do
    gext enable "$ext"
  done
}

uninstall_extensions() {
  echo "🧹 Removing extensions..."
  for ext in "${EXTENSIONS[@]}"; do
    if command -v gext >/dev/null; then
      gext uninstall "$ext" || echo "⚠️ Failed to uninstall $ext"
    else
      echo "⚠️ Cannot uninstall $ext — 'gext' not found"
    fi
  done
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install, configure, and enable extensions"
  echo "  install  Install dependencies and extensions"
  echo "  config   Compile schemas and enable extensions"
  echo "  clean    Uninstall extensions"
}

case "$1" in
  all)
    install_dependencies
    install_extensions
    compile_schemas
    configure_extensions
    enable_extensions
    ;;
  install)
    install_dependencies
    install_extensions
    ;;
  config)
    compile_schemas
    configure_extensions
    enable_extensions
    ;;
  clean)
    uninstall_extensions
    ;;
  *)
    show_help
    ;;
esac
