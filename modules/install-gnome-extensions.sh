#!/bin/bash
set -e

MODULE_NAME="gnome-extensions"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
TMP_ZIP="/tmp/ext.zip"
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
EXTENSIONS=(
  "blur-my-shell@aunetx"
  "rounded-window-corners@fxgn"
  "tilingshell@ferrarodomenico.com"
)
TO_ENABLE_AFTER_LOGIN=()
ACTION="${1:-all}"

install_dependencies() {
  echo "🔧 Installing required dependencies..."
  sudo apt update
  sudo apt install -y curl unzip jq gnome-shell-extension-prefs dconf-cli
}

reload_gnome_shell() {
  echo ""
  echo "🔁 Extensions installed."
  echo "🚨 Please log out and back in to complete activation."
  echo ""
}

enable_extension_safely() {
  local uuid="$1"
  if gnome-extensions list | grep -q "$uuid"; then
    echo "✅ Enabling $uuid"
    gnome-extensions enable "$uuid" && echo "🟢 $uuid enabled."
  else
    echo "⚠️ $uuid is not yet registered. Will be enabled after login."
    TO_ENABLE_AFTER_LOGIN+=("$uuid")
  fi
}

install_extensions() {
  echo "🧩 Installing GNOME extensions..."
  mkdir -p "$EXT_DIR"

  for EXT_ID in "${EXTENSIONS[@]}"; do
    echo "🌐 Searching for $EXT_ID..."
    METADATA=$(curl -s "https://extensions.gnome.org/extension-query/?search=${EXT_ID}" | jq -r --arg uuid "$EXT_ID" '.extensions[] | select(.uuid == $uuid)')

    if [[ -z "$METADATA" ]]; then
      echo "❌ Extension $EXT_ID not found."
      continue
    fi

    PK_ID=$(echo "$METADATA" | jq -r '.pk')
    VERSION_JSON=$(curl -s "https://extensions.gnome.org/extension-info/?pk=${PK_ID}&shell_version=${GNOME_VERSION}")
    DL_URL="https://extensions.gnome.org$(echo "$VERSION_JSON" | jq -r '.download_url')"

    echo "⬇️ Downloading $EXT_ID..."
    curl -sL "$DL_URL" -o "$TMP_ZIP"

    TMP_UNPACK=$(mktemp -d)
    unzip -oq "$TMP_ZIP" -d "$TMP_UNPACK"

    METADATA_PATH=$(find "$TMP_UNPACK" -type f -name metadata.json | head -n1)
    [[ -z "$METADATA_PATH" ]] && echo "❌ metadata.json not found" && continue

    ACTUAL_UUID=$(jq -r '.uuid' "$METADATA_PATH")
    [[ -z "$ACTUAL_UUID" || "$ACTUAL_UUID" == "null" ]] && echo "❌ UUID not found in metadata.json" && continue

    echo "📛 UUID: $ACTUAL_UUID"
    DEST="$EXT_DIR/$ACTUAL_UUID"
    EXT_ROOT="$(dirname "$METADATA_PATH")"

    echo "📁 Installing to $DEST"
    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp -r "$EXT_ROOT"/* "$DEST"

    if [[ -d "$DEST/schemas" ]]; then
      echo "🔧 Compiling schemas for $ACTUAL_UUID..."
      glib-compile-schemas "$DEST/schemas"

      echo "📂 Copying schemas to user schema directory..."
      mkdir -p ~/.local/share/glib-2.0/schemas
      find "$DEST/schemas" -name '*.gschema.xml' -exec cp {} ~/.local/share/glib-2.0/schemas/ \;
    fi

    enable_extension_safely "$ACTUAL_UUID"
  done

  if [[ -d ~/.local/share/glib-2.0/schemas ]]; then
    echo "🧠 Recompiling user schema directory..."
    glib-compile-schemas ~/.local/share/glib-2.0/schemas/
  fi

  if [[ ${#TO_ENABLE_AFTER_LOGIN[@]} -gt 0 ]]; then
    echo "💾 Updating enabled-extensions GSettings list..."
    CURRENT=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null | jq -c '.' 2>/dev/null || echo '[]')
    for uuid in "${TO_ENABLE_AFTER_LOGIN[@]}"; do
      CURRENT=$(echo "$CURRENT" | jq -c "unique + [\"$uuid\"]")
    done
    gsettings set org.gnome.shell enabled-extensions "$CURRENT"
  fi

  reload_gnome_shell
}

config_extensions() {
  echo "⚙️ Configuring installed extensions..."

  export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"

  echo "🎨 Configuring Blur My Shell..."
  gsettings set org.gnome.shell.extensions.blur-my-shell brightness 0.8
  gsettings set org.gnome.shell.extensions.blur-my-shell sigma 30
  gsettings set org.gnome.shell.extensions.blur-my-shell color-and-noise true
  gsettings set org.gnome.shell.extensions.blur-my-shell hacks-level 1

  echo "🧩 Setting Blur My Shell [panel] config via dconf..."
  if command -v dconf &>/dev/null; then
    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/pipeline "'pipeline_default_rounded'" || echo "⚠️ Failed to set pipeline."
    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/override-background-dynamically false || echo "⚠️ Failed to set override-background-dynamically."

    echo "🔍 Verifying panel config:"
    dconf read /org/gnome/shell/extensions/blur-my-shell/panel/pipeline || echo "(pipeline not readable)"
    dconf read /org/gnome/shell/extensions/blur-my-shell/panel/override-background-dynamically || echo "(override-background-dynamically not readable)"
  else
    echo "❌ 'dconf' not available. Skipping panel configuration."
  fi

  echo "🧱 Configuring Tiling Shell..."
  gsettings set org.gnome.shell.extensions.tilingshell gaps-inner 8
  gsettings set org.gnome.shell.extensions.tilingshell gaps-outer 10
  gsettings set org.gnome.shell.extensions.tilingshell window-gap true
  gsettings set org.gnome.shell.extensions.tilingshell tile-animation-duration 0.15
  gsettings set org.gnome.shell.extensions.tilingshell show-title true
  gsettings set org.gnome.shell.extensions.tilingshell title-position "'top'"
}

reset_extensions() {
  echo "♻️ Resetting extension settings to defaults..."
  for schema in \
    org.gnome.shell.extensions.blur-my-shell \
    org.gnome.shell.extensions.rounded-window-corners-reborn \
    org.gnome.shell.extensions.tilingshell; do
    echo "🔄 Resetting $schema..."
    gsettings reset-recursively "$schema" || true
  done
}

clean_extensions() {
  echo "🧼 Removing extensions..."

  for EXT_ID in "${EXTENSIONS[@]}"; do
    echo "🌐 Searching for $EXT_ID..."
    METADATA=$(curl -s "https://extensions.gnome.org/extension-query/?search=${EXT_ID}" | jq -r --arg uuid "$EXT_ID" '.extensions[] | select(.uuid == $uuid)')

    [[ -z "$METADATA" ]] && echo "⚠️ Skipping unknown $EXT_ID" && continue

    PK_ID=$(echo "$METADATA" | jq -r '.pk')
    VERSION_JSON=$(curl -s "https://extensions.gnome.org/extension-info/?pk=${PK_ID}&shell_version=${GNOME_VERSION}")
    DL_URL="https://extensions.gnome.org$(echo "$VERSION_JSON" | jq -r '.download_url')"

    curl -sL "$DL_URL" -o "$TMP_ZIP"
    TMP_UNPACK=$(mktemp -d)
    unzip -oq "$TMP_ZIP" -d "$TMP_UNPACK"

    METADATA_PATH=$(find "$TMP_UNPACK" -type f -name metadata.json | head -n1)
    ACTUAL_UUID=$(jq -r '.uuid' "$METADATA_PATH")

    echo "❌ Removing $ACTUAL_UUID"
    gnome-extensions disable "$ACTUAL_UUID" 2>/dev/null || true
    rm -rf "$EXT_DIR/$ACTUAL_UUID"
  done
}

# === Main Dispatcher ===
case "$ACTION" in
  install)
    install_dependencies
    install_extensions
    ;;
  config)
    config_extensions
    ;;
  reset)
    reset_extensions
    ;;
  clean)
    clean_extensions
    ;;
  all)
    install_dependencies
    install_extensions
    config_extensions
    ;;
  *)
    echo "Usage: $0 [install|config|reset|clean|all]"
    exit 1
    ;;
esac
