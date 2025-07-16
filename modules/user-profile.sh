#!/bin/bash
set -e

MODULE_NAME="user-profile"
CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/userinfo.config"
ACTION="${1:-all}"

ask_user_profile() {
  while true; do
    gum format --theme=dark <<EOF
# 📧 Let's set up your email address

This will be used for:

- ✅ Git configuration  
EOF

    # Load existing email value if present
    if [[ -f "$CONFIG_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$CONFIG_FILE"
    fi

    # === Prompt for email ===
    USER_EMAIL=$(gum input \
      --prompt "📧 Email address: " \
      --placeholder "bernt@example.com" \
      --value "${email:-}")

    # === Show review of email ===
    gum format --theme=dark <<<"# Review your info

✅ Email: **$USER_EMAIL**"

    # === Confirm and save email ===
    if gum confirm "💾 Save this email?"; then
      mkdir -p "$CONFIG_DIR"
      cat > "$CONFIG_FILE" <<EOF
email="$USER_EMAIL"
EOF
      gum style --foreground 2 "✅ Saved email to $CONFIG_FILE"
      break
    else
      gum style --foreground 3 "🔁 Let's try again..."
    fi
  done
}

# === Dispatcher ===
case "$ACTION" in
  install|config|all)
    ask_user_profile
    ;;
  clean)
    rm -f "$CONFIG_FILE"
    gum style --foreground 1 "🗑️ Removed $CONFIG_FILE"
    ;;
  *)
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
