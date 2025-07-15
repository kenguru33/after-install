ask_user_profile() {
  gum format --theme=dark <<EOF
# 👤 Let's personalize your setup

This information will be used for:

- ✅ Git configuration  
- 🖼️  Gravatar profile image
EOF

  # === Load existing values if present ===
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi

  # === Prompt for full name (with default) ===
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

  # === Prompt and validate email (with default) ===
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

  # === Show a summary ===
  printf "# Review your info\n\n✅ Name: **%s**\n✅ Email: **%s**\n" "$USER_NAME" "$USER_EMAIL" \
    | gum format --theme=dark

  # === Confirm and save ===
  gum confirm "💾 Save this information?" || exit 1

  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<EOF
name="$USER_NAME"
email="$USER_EMAIL"
EOF

  gum style --foreground 2 "✅ Saved user info to $CONFIG_FILE"
}
