#!/bin/bash
set -e

MODULE_NAME="blackbox-terminal"
SCHEME_DIR="$HOME/.local/share/blackbox/schemes"
PALETTE_NAME="catppuccin-mocha"
SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
SCHEMA_FILE="$SCHEMA_DIR/org.gnome.blackbox.gschema.xml"
ACTION="${1:-all}"

install_blackbox() {
  echo "📦 Installing BlackBox Terminal from apt..."

  if ! command -v blackbox &>/dev/null; then
    sudo apt update
    sudo apt install -y blackbox-terminal
    echo "✅ BlackBox installed."
  else
    echo "ℹ️ BlackBox is already installed."
  fi
}

install_catppuccin_theme() {
  echo "🎨 Installing Catppuccin Mocha theme..."
  mkdir -p "$SCHEME_DIR"

  if [[ ! -f "$SCHEME_DIR/$PALETTE_NAME.json" ]]; then
    TMP_DIR=$(mktemp -d)
    git clone --depth=1 https://github.com/catppuccin/tilix.git "$TMP_DIR"
    cp "$TMP_DIR/themes/$PALETTE_NAME.json" "$SCHEME_DIR/$PALETTE_NAME.json"
    rm -rf "$TMP_DIR"
    echo "✅ Theme installed to $SCHEME_DIR"
  else
    echo "ℹ️ Theme already installed."
  fi
}

ensure_blackbox_schema() {
  echo "📦 Ensuring BlackBox GSettings schema exists..."

  mkdir -p "$SCHEMA_DIR"

  cat > "$SCHEMA_FILE" <<EOF
<schemalist>
  <schema id="org.gnome.blackbox.preferences" path="/org/gnome/blackbox/preferences/">
    <key name="font" type="s">
      <default>'Monospace 11'</default>
    </key>
    <key name="theme" type="s">
      <default>'default'</default>
    </key>
    <key name="padding" type="i">
      <default>6</default>
    </key>
  </schema>
</schemalist>
EOF

  echo "🧠 Compiling schema to $SCHEMA_DIR..."
  glib-compile-schemas "$SCHEMA_DIR"
}

config_blackbox() {
  echo "🎨 Configuring BlackBox with Catppuccin Mocha + Hack Nerd Font Mono..."

  export GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR"

  gsettings set org.gnome.blackbox.preferences font 'Hack Nerd Font Mono 11'
  gsettings set org.gnome.blackbox.preferences theme "$PALETTE_NAME"
  gsettings set org.gnome.blackbox.preferences padding 8

  echo "✅ BlackBox configuration applied via GSettings."
}

clean_blackbox() {
  echo "🗑️ Cleaning up BlackBox terminal and theme files..."
  sudo apt purge -y blackbox-terminal || true
  rm -f "$SCHEME_DIR/$PALETTE_NAME.json"
  rm -f "$SCHEMA_FILE"
  glib-compile-schemas "$SCHEMA_DIR"
  echo "✅ Cleanup done."
}

case "$ACTION" in
  install)
    install_blackbox
    install_catppuccin_theme
    ;;
  config)
    ensure_blackbox_schema
    config_blackbox
    ;;
  clean)
    clean_blackbox
    ;;
  all)
    install_blackbox
    install_catppuccin_theme
    ensure_blackbox_schema
    config_blackbox
    ;;
  *)
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
