#!/bin/bash
set -e

MODULE_NAME="user-profile"
CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/userinfo.config"
ACTION="${1:-all}"

ask_user_profile() {
  gum format --theme=dark <<EOF
# 👤 Let's personalize your setup

This information will be used for:

- ✅ Git configuration
- 🖼️  Gravatar-based profile image
EOF

  gum confirm "Do you want to continue?" || exit 1

  USER_NAME=$(gum input --prompt "📝 Full name: " --placeholder "Bernt Anker")
  USER_EMAIL=$(gum input --prompt "📧 Email address: " --placeholder "bernt@example.com")

  if [[ -z "$USER_NAME" || -z "$USER_EMAIL" ]]; then
    gum style --foreground 1 "❌ Name and email cannot be empty."
    exit 1
  fi

  gum format <<EOF
✅ Name: **$USER_NAME**
✅ Email: **$USER_EMAIL**
EOF

  gum confirm "Is this correct?" || exit 1

  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<EOF
name="$USER_NAME"
email="$USER_EMAIL"
EOF

  gum style --foreground 2 "💾 Saved user info to $CONFIG_FILE"
}

config_user_profile() {
  if [[ -f "$CONFIG_FILE" ]]; then
    gum style --foreground 2 "ℹ️  User info already exists: $CONFIG_FILE"
  else
    ask_user_profile
  fi
}

clean_user_profile() {
  rm -f "$CONFIG_FILE"
  gum style --foreground 1 "🗑️ Removed $CONFIG_FILE"
}

case "$ACTION" in
  install) ask_user_profile ;;
  config) config_user_profile ;;
  clean) clean_user_profile ;;
  all)
    config_user_profile
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
