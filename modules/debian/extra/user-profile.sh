#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/userinfo.config"

# === OS Detection ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

# === Dependency Check ===
if ! command -v gum &>/dev/null; then
  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    echo "📦 Installing missing dependency: gum"
    sudo apt update
    sudo apt install -y gum
  else
    echo "❌ Unsupported OS: $ID. Only Debian-based systems are supported."
    exit 1
  fi
fi

# === Load existing fallback values if config exists ===
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
fallback_name="${name:-}"
fallback_email="${email:-}"

# === Prompt ===
while true; do
  gum format --theme=dark <<EOF
# 👤 Let's personalize your setup

This information will be used for:

- ✅ Git configuration  
- 🖼️  Gravatar profile image
EOF

  while true; do
    USER_NAME=$(gum input \
      --prompt "📝 Full name: " \
      --placeholder "Bernt Anker" \
      --value "$fallback_name" \
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
      --value "$fallback_email" \
      --width 50)

    if [[ -z "$USER_EMAIL" ]]; then
      gum style --foreground 1 "❌ Email cannot be empty."
    elif [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      break
    else
      gum style --foreground 1 "❌ Invalid email format. Please try again."
    fi
  done

  gum format --theme=dark <<<"# Review your info

✅ Name: $USER_NAME  
✅ Email: $USER_EMAIL"

  if gum confirm "💾 Save this information?"; then
    mkdir -p "$CONFIG_DIR"
    cat >"$CONFIG_FILE" <<EOF
name="$USER_NAME"
email="$USER_EMAIL"
EOF
    gum style --foreground 2 "✅ Saved user info to $CONFIG_FILE"
    break
  else
    gum style --foreground 3 "🔁 Let's try again..."
    clear
    if [[ -x "$MODULES/banner.sh" ]]; then
      "$MODULES/banner.sh"
    else
      gum style --foreground 1 "❌ Unable to find or execute the banner script at $MODULES/banner.sh"
    fi
  fi
done
