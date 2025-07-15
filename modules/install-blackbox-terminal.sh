#!/bin/bash
set -e

EXTENSION_ID="blur-my-shell@aunetx"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID"
SCHEMA_FILE="org.gnome.shell.extensions.blur-my-shell.gschema.xml"
USER_SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
ACTION="${1:-all}"

# Load shared dependency installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ensure-gext.sh"

install_extension() {
  echo "🔌 Installing Blur My Shell extension..."
  ensure_gext_installed
  gext install "$EXTENSION_ID"
}

register_schema() {
  echo "🧠 Registering GSettings schema for Blur My Shell..."

  local schema_path="$EXTENSION_DIR/schemas/$SCHEMA_FILE"
  if [[ ! -f "$schema_path" ]]; then
    echo "❌ Schema file not found: $schema_path"
    return 1
  fi

  mkdir -p "$USER_SCHEMA_DIR"
  cp "$schema_path" "$USER_SCHEMA_DIR/"
  glib-compile-schemas "$USER_SCHEMA_DIR"
}

configure_extension() {
  echo "🎛️  Configuring Blur My Shell via GSettings..."

  gsettings set org.gnome.shell.extensions.blur-my-shell brightness 0.8
  gsettings set org.gnome.shell.extensions.blur-my-shell sigma 30
  gsettings set org.gnome.shell.extensions.blur-my-shell pipeline "'pipeline_default_rounded'"
  gsettings set org.gnome.shell.extensions.blur-my-shell color-and-noise true
  gsettings set org.gnome.shell.extensions.blur-my-shell hacks-level 1
}

enable_extension() {
  echo "✅ Enabling extension..."
  gnome-extensions enable "$EXTENSION_ID" || true
}

clean_extension() {
  echo "🧹 Cleaning up Blur My Shell schema..."
  rm -f "$USER_SCHEMA_DIR/$SCHEMA_FILE"
  glib-compile-schemas "$USER_SCHEMA_DIR"
}

case "$ACTION" in
  install)
    install_extension
    ;;
  config)
    register_schema
    configure_extension
    enable_extension
    ;;
  all)
    install_extension
    register_schema
    configure_extension
    enable_extension
    ;;
  clean)
    clean_extension
    ;;
  *)
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac
