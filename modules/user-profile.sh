#!/bin/bash
set -e

MODULE_NAME="user-profile"
CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/userinfo.config"
ACTION="${1:-all}"

ask_user_profile() {
  while true; do
    gum format --theme=dark <<EOF
# 👤 Let's personalize your setup

This information will be used for:

- ✅ Git configuration  
- 🖼️  Gravatar profile image
EOF

    # Load existing values if present
    if [[ -f "$CONFIG_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$CONFIG_FILE"
    fi

    # === Prompt for full name (with fallback value) ===
    USER_NAME=$(gum input \
      --prompt "📝 Full name: " \
      --placeholder "Bernt Anker" \
      --value "${name:-}" \
      --width 50)

    # === Prompt for email (with fallback value) ===
    USER_EMAIL=$(gum input \
      --prompt "📧 Email address: " \
      --placeholder "bernt@example.com" \
      --value "${email:-}" \
      --width 50)

    # === Escape @ for gum markdown formatting ===
    escaped_name="${USER_NAME//\\/\\\\}"
    escaped_name="${escaped_name//\*/\\*}"
    escaped_email="${USER_EMAIL//@/\\@}"

    # === Show review ===
    gum format --theme=dark <<<"# Review your info

✅ Name: **$escaped_name**  
✅ Email: **$escaped_email**"

    if gum confirm "💾 Save this information?"; then
      mkdir -p "$CONFIG_DIR"
      cat > "$CONFIG_FILE" <<EOF
name="$USER_NAME"
email="$USER_EMAIL"
EOF
      gum style --foreground 2 "✅ Saved user info to $CONFIG_FILE"
      break
    else
      gum style --foreground 3 "🔁 Let's try again..."
    fi
  done
}

config_user_profile() {
  ask_user_profile
}

clean_user_profile() {
  rm -f "$CONFIG_FILE"
  gum style --foreground 1 "🗑️ Removed $CONFIG_FILE"
}

# === Dispatcher ===
case "$ACTION" in
  install|config|all)
    config_user_profile
    ;;
  clean)
    clean_user_profile
    ;;
  *)
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
