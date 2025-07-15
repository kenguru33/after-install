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

    # === Prompt full name ===
    while true; do
      read -r USER_NAME <<<"$(gum input \
        --prompt "📝 Full name: " \
        --placeholder "Bernt Anker" \
        --value "${name:-}" \
        --width 50 | tr -d '\r')"

      if [[ -z "$USER_NAME" ]]; then
        gum style --foreground 1 "❌ Name cannot be empty."
      else
        break
      fi
    done

    # === Prompt email ===
    while true; do
      read -r USER_EMAIL <<<"$(gum input \
        --prompt "📧 Email address: " \
        --placeholder "bernt@example.com" \
        --value "${email:-}" \
        --width 50 | tr -d '\r')"

      if [[ -z "$USER_EMAIL" ]]; then
        gum style --foreground 1 "❌ Email cannot be empty."
      elif [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        break
      else
        gum style --foreground 1 "❌ Invalid email format. Please try again."
      fi
    done

    # === Review info ===
    printf "# Review your info\n\n✅ Name: **%s**\n✅ Email: **%s**\n" "$USER_NAME" "$USER_EMAIL" \
      | gum format --theme=dark

    # === Confirm ===
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
