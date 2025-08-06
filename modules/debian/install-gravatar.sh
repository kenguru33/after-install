#!/bin/bash
set -e

MODULE_NAME="set-user-avatar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_PROFILE_SCRIPT="$SCRIPT_DIR/extra/user-profile.sh"

FACE_IMAGE="$HOME/.face"
AFTER_INSTALL_CONFIG="$HOME/.config/after-install/userinfo.config"
MODULE_EMAIL_FILE="$HOME/.config/$MODULE_NAME/email"
GDM_ICON_DIR="/var/lib/AccountsService/icons"
DEFAULT_SIZE=256

ACTION="${1:-all}"
EMAIL="${2:-}"
SIZE="${3:-$DEFAULT_SIZE}"

# === Ensure Debian ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
    echo "❌ This script is for Debian only."
    exit 1
  fi
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

# === Dependencies ===
DEPS=("curl")

install_dependencies() {
  echo "📦 Installing dependencies..."
  sudo apt update
  for dep in "${DEPS[@]}"; do
    if ! dpkg -l | grep -qw "$dep"; then
      echo "📦 Installing $dep..."
      sudo apt install -y "$dep"
    else
      echo "✅ $dep is already installed."
    fi
  done
}

# === Load email from user-profile ===
load_email_from_user_profile() {
  if [[ ! -f "$AFTER_INSTALL_CONFIG" ]]; then
    echo "📁 User config not found. Running user-profile to collect info..."
    "$USER_PROFILE_SCRIPT"
  fi

  source "$AFTER_INSTALL_CONFIG"

  if [[ -z "$email" ]]; then
    echo "⚠️  Email missing in config. Running user-profile again..."
    "$USER_PROFILE_SCRIPT"
    source "$AFTER_INSTALL_CONFIG"
  fi

  if [[ -z "$email" ]]; then
    echo "❌ Still missing email after running user-profile. Exiting."
    exit 1
  fi

  EMAIL="$email"
}

# === Determine email ===
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

  load_email_from_user_profile
}

install() {
  echo "📦 No-op install step. Nothing to do here for now."
}

config() {
  find_email

  mkdir -p "$(dirname "$MODULE_EMAIL_FILE")"
  echo "$EMAIL" >"$MODULE_EMAIL_FILE"

  HASH=$(echo -n "$EMAIL" | tr '[:upper:]' '[:lower:]' | md5sum | cut -d' ' -f1)
  GRAVATAR_URL="https://www.gravatar.com/avatar/$HASH?s=$SIZE&d=identicon"

  echo "⬇️  Downloading Gravatar from: $GRAVATAR_URL"
  curl -sL "$GRAVATAR_URL" -o "$FACE_IMAGE"
  echo "🖼️  Saved avatar to $FACE_IMAGE"

  # Set GNOME account picture via gsettings if possible
  if command -v gsettings &>/dev/null; then
    echo "🔧 Setting GNOME account picture via gsettings..."
    gsettings set org.gnome.desktop.account-service account-picture "$FACE_IMAGE" 2>/dev/null || true
  fi

  # Copy to GDM location
  echo "🔧 Setting GDM login avatar..."
  sudo mkdir -p "$GDM_ICON_DIR"
  sudo cp "$FACE_IMAGE" "$GDM_ICON_DIR/$(whoami)"

  # Set in AccountsService
  ACCOUNTS_USER_CONFIG="/var/lib/AccountsService/users/$(whoami)"
  sudo mkdir -p "$(dirname "$ACCOUNTS_USER_CONFIG")"
  sudo tee "$ACCOUNTS_USER_CONFIG" >/dev/null <<EOF
[User]
Icon=$GDM_ICON_DIR/$(whoami)
EOF

  echo "✅ GNOME and GDM avatar updated."
}

clean() {
  echo "🧹 Removing avatar and email config..."
  rm -f "$FACE_IMAGE"
  rm -f "$MODULE_EMAIL_FILE"
  echo "✅ Clean complete."
}

all() {
  install_dependencies
  config
}

# === Entry Point ===
case "$ACTION" in
  all) all ;;
  deps) install_dependencies ;;
  install) install ;;
  config) config ;;
  clean) clean ;;
  *)
    echo "Usage: $0 {all|deps|install|config|clean} [email] [size]"
    exit 1
    ;;
esac
