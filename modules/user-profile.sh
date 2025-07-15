#!/bin/bash
set -e

MODULE_NAME="user-profile"
CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/userinfo.config"
ACTION="${1:-all}"

ask_user_profile() {
  echo "🧪 Running ask_user_profile()" # debug

  gum format --theme=dark <<EOF
# 👤 Let's personalize your setup

This information will be used for:

- ✅ Git configuration  
- 🖼️  Gravatar profile image
EOF

  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi

  while true; do
    USER_NAME=$(gum input \
      --prompt "📝 Full name: " \
      --placeholder "Bernt Anker" \
      --value "${name:-}" \
      --width 50)

    if [[ -z "$USER_NAME" ]]; then
      gum style --foreground 1 "❌ Name cannot be empty."
    else
      break
    fi
  done

  while true; do
    USER_EMAIL=$(gum input \
      --prompt "📧 Email address: " \
      --placeholder "bernt@example.com" \
      --value "${email:-}" \
      --width 50)

    if [[ -z "$USER_EMAIL" ]]; then
      gum style --foreground 1 "❌ Email cannot be empty."
    elif [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      break
    else
      gum style --foreground 1 "❌ Invalid email format. Please try again."
    fi
  done

  printf "# Review your info\n\n✅ Name: **%s**\n✅ Email: **%s**\n" "$USER_NAME" "$USER_EMAIL" \
    | gum format --theme=dark

  gum confirm "💾 Save this information?" || exit 1

  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<EOF
name="$USER_NAME"
email="$USER_EMAIL"
EOF

  gum style --foreground 2 "✅ Saved user info to $CONFIG_FILE"
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
