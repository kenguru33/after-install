#!/bin/bash
set -e

ACTION="${1:-all}"
SCRIPT_NAME="install-chrome"
DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
DEB_FILE="/tmp/google-chrome.deb"
PREF_FILE="$HOME/.config/google-chrome/Default/Preferences"

install() {
  echo "🌐 [$SCRIPT_NAME] Downloading Google Chrome..."
  wget -q --show-progress "$DEB_URL" -O "$DEB_FILE"

  echo "📦 [$SCRIPT_NAME] Installing Chrome..."
  sudo dpkg -i "$DEB_FILE" || true
  sudo apt-get install -f -y

  echo "✅ [$SCRIPT_NAME] Chrome installed."
}

config() {
  echo "⚙️ [$SCRIPT_NAME] Enabling 'Use system title bar and borders'..."

  if [[ ! -f "$PREF_FILE" ]]; then
    echo "🚫 [$SCRIPT_NAME] Chrome preferences not found. Please launch Chrome once and close it."
    exit 1
  fi

  jq '.browser.custom_chrome_frame = false' "$PREF_FILE" > "$PREF_FILE.tmp" && mv "$PREF_FILE.tmp" "$PREF_FILE"

  echo "✅ [$SCRIPT_NAME] System title bar enabled. Chrome will now use GTK decorations."
}

clean() {
  echo "🧹 [$SCRIPT_NAME] Cleaning up..."
  rm -f "$DEB_FILE"
}

all() {
  install
  echo "👉 Please launch Chrome once, then run:"
  echo "   modules/install-chrome.sh config"
}

case "$ACTION" in
  install) install ;;
  config) config ;;
  clean) clean ;;
  all) all ;;
  *) echo "❌ [$SCRIPT_NAME] Unknown action: $ACTION. Use: all | install | config | clean" ;;
esac
