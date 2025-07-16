#!/bin/bash
set -e

MODULE_NAME="set-user-avatar"
FACE_IMAGE="$HOME/.face"
AFTER_INSTALL_CONFIG="$HOME/.config/after-install/userinfo.config"
MODULE_EMAIL_FILE="$HOME/.config/$MODULE_NAME/email"
DEFAULT_SIZE=256

ACTION="${1:-all}"
EMAIL="${2:-}"
SIZE="${3:-$DEFAULT_SIZE}"

# === Functions ===

find_email() {
  if [[ -n "$EMAIL" ]]; then
    return
  fi

  if [[ -f "$AFTER_INSTALL_CONFIG" ]]; then
    EMAIL=$(grep -i '^email=' "$AFTER_INSTALL_CONFIG" | cut -d= -f2 | xargs)
    if [[ -n "$EMAIL" ]]; then
      echo "📄 Loaded email from $AFTER_INSTALL_CONFIG: $EMAIL"
      return
    fi
  fi

  if [[ -f "$MODULE_EMAIL_FILE" ]]; then
    EMAIL=$(<"$MODULE_EMAIL_FILE")
    echo "📄 Loaded email from $MODULE_EMAIL_FILE: $EMAIL"
    return
  fi

  echo "❌ No email provided and none found in after-install config or module config."
  echo "Usage: $0 config your@email.com [size]"
  exit 1
}

install() {
  echo "📦 Installing required dependency: curl"
  if ! command -v curl &>/dev/null; then
    sudo apt update
    sudo apt install -y curl
  else
    echo "✅ curl is already installed."
  fi
}

config() {
  find_email

  mkdir -p "$(dirname "$MODULE_EMAIL_FILE")"
  echo "$EMAIL" > "$MODULE_EMAIL_FILE"

  HASH=$(echo -n "$EMAIL" | tr '[:upper:]' '[:lower:]' | md5sum | cut -d' ' -f1)
  GRAVATAR_URL="https://www.gravatar.com/avatar/$HASH?s=$SIZE&d=identicon"

  echo "⬇️ Downloading Gravatar from: $GRAVATAR_URL"
  curl -sL "$GRAVATAR_URL" -o "$FACE_IMAGE"

  echo "🖼️ Saved avatar to $FACE_IMAGE"

  if command -v gsettings &>/dev/null; then
    echo "🔧 Setting GNOME account picture via gsettings..."
    gsettings set org.gnome.desktop.account-service account-picture "$FACE_IMAGE" 2>/dev/null || true
  fi

  echo "✅ GNOME avatar updated."
}

clean() {
  echo "🧹 Removing avatar and module email config..."
  rm -f "$FACE_IMAGE"
  rm -f "$MODULE_EMAIL_FILE"
  echo "✅ Clean complete."
}

all() {
  install
  config
}

# === Main Switch ===
case "$ACTION" in
  install) install ;;
  config) config ;;
  clean) clean ;;
  all) all ;;
  *)
    echo "Usage: $0 {install|config|clean|all} [email] [size]"
    exit 1
    ;;
esac
