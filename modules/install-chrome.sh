#!/bin/bash
set -e

ACTION="${1:-all}"
SCRIPT_NAME="install-chrome"
DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
DEB_FILE="/tmp/google-chrome.deb"
PREF_DIR="$HOME/.config/google-chrome/Default"
PREF_FILE="$PREF_DIR/Preferences"
DESKTOP_FILE="$HOME/.local/share/applications/google-chrome.desktop"

install() {
  echo "🌐 [$SCRIPT_NAME] Downloading Google Chrome..."
  wget -q --show-progress "$DEB_URL" -O "$DEB_FILE"

  echo "📦 [$SCRIPT_NAME] Installing Chrome..."
  sudo dpkg -i "$DEB_FILE" || true
  sudo apt-get install -f -y

  echo "✅ [$SCRIPT_NAME] Chrome installed."
}

config() {
  echo "⚙️ [$SCRIPT_NAME] Enabling GTK window controls and GNOME theme..."

  # Create Preferences file if Chrome hasn't been launched yet
  mkdir -p "$PREF_DIR"
  if [[ -f "$PREF_FILE" ]]; then
    echo "🛠️ Patching Preferences to use GTK decorations..."
    jq '.browser.custom_chrome_frame = false' "$PREF_FILE" > "$PREF_FILE.tmp" && mv "$PREF_FILE.tmp" "$PREF_FILE"
  else
    echo "🛠️ Creating Preferences with GTK decoration enabled..."
    cat <<EOF > "$PREF_FILE"
{
  "browser": {
    "custom_chrome_frame": false
  }
}
EOF
  fi

  # Patch desktop file to force GTK theming and Wayland if needed
  mkdir -p "$(dirname "$DESKTOP_FILE")"
  cp /usr/share/applications/google-chrome.desktop "$DESKTOP_FILE" 2>/dev/null || true

  if [[ -f "$DESKTOP_FILE" ]]; then
    sed -i 's|Exec=/usr/bin/google-chrome-stable.*|Exec=/usr/bin/google-chrome-stable --gtk-version=4 --ozone-platform=wayland|g' "$DESKTOP_FILE"
    echo "✅ [$SCRIPT_NAME] Patched launcher Exec line with GTK + Wayland flags."
  else
    echo "⚠️ [$SCRIPT_NAME] Failed to patch desktop entry. Chrome may need to be launched once."
  fi
}

clean() {
  echo "🧹 [$SCRIPT_NAME] Cleaning up..."
  rm -f "$DEB_FILE"
}

all() {
  install
  config
  clean
}

case "$ACTION" in
  install) install ;;
  config)  config ;;
  clean)   clean ;;
  all)     all ;;
  *)
    echo "❌ [$SCRIPT_NAME] Unknown action: $ACTION. Use: all | install | config | clean"
    exit 1
    ;;
esac
