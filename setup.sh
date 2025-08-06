#!/bin/bash
set -e
trap 'echo "❌ Script failed at $BASH_COMMAND" >&2' ERR

# === Argument Parsing ===
VERBOSE=false
if [[ "$1" == "--verbose" ]]; then
  VERBOSE=true
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-"$SCRIPT_DIR/modules/debian"}"
CONFIG_DIR="$HOME/.config/after-install"
GIT_CONFIG="$CONFIG_DIR/user-git-info.config"
AVATAR_CONFIG="$CONFIG_DIR/set-user-avatar.config"
mkdir -p "$CONFIG_DIR"

# === Ensure git, gum, wget ===
ensure_deps() {
  echo "🔧 Checking for required tools..."
  sudo apt update -y >/dev/null 2>&1
  sudo apt install -y git wget >/dev/null 2>&1

  if ! command -v gum >/dev/null 2>&1; then
    echo "deb [trusted=yes] https://apt.charm.sh/ stable main" | \
      sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
    sudo apt update -y >/dev/null 2>&1
    sudo apt install -y gum >/dev/null 2>&1
  fi
}
ensure_deps

# === Splash Screen ===
clear; clear; clear
gum style \
  --border double \
  --padding "1 6" \
  --margin "2" \
  --width 70 \
  --align center \
  --foreground 219 \
  --border-foreground 213 \
  "✨ Glans Setup ✨" \
  "" \
  "An opinionated post-installation tool for Debian Trixie" \
  ""

# === Ask for Sudo ===
echo ""
echo "🔐 This setup requires sudo privileges..."
sudo -v
gum style --foreground 10 "✅ Sudo access granted."

# === Load existing config (if any) ===
[[ -f "$GIT_CONFIG" ]] && source "$GIT_CONFIG"
[[ -f "$AVATAR_CONFIG" ]] && source "$AVATAR_CONFIG"

# === Git Config Prompt ===
echo ""
gum style --padding "0 2" "🛠 Git configuration (used for commit identity)"
DEFAULT_NAME="${name:-$(git config --global user.name || echo "")}"
DEFAULT_EMAIL="${email:-$(git config --global user.email || echo "")}"
DEFAULT_EDITOR="${editor:-nvim}"
DEFAULT_BRANCH="${branch:-main}"
DEFAULT_REBASE="${rebase:-true}"

name=$(gum input --value "$DEFAULT_NAME" --placeholder "Full Name" --prompt "👤 Name: ")
email=$(gum input --value "$DEFAULT_EMAIL" --placeholder "you@example.com" --prompt "📧 Email: ")
editor=$(gum input --value "$DEFAULT_EDITOR" --placeholder "nano/nvim/vim" --prompt "📝 Default editor: ")
branch=$(gum input --value "$DEFAULT_BRANCH" --prompt "🌿 Default branch: ")
if gum confirm "🔄 Use rebase when pulling?"; then
  rebase="true"
else
  rebase="false"
fi

cat > "$GIT_CONFIG" <<EOF
name="$name"
email="$email"
editor="$editor"
branch="$branch"
rebase="$rebase"
EOF
gum style --foreground 10 "✅ Git config saved"

# === Gravatar Config Prompt ===
echo ""
gum style --padding "0 2" "📸 Gravatar email (used to download your profile picture)"
DEFAULT_GRAVATAR_EMAIL="${gravatar_email:-$email}"
gravatar_email=$(gum input --value "$DEFAULT_GRAVATAR_EMAIL" --prompt "📧 Gravatar Email: ")
echo "gravatar_email=\"$gravatar_email\"" > "$AVATAR_CONFIG"
gum style --foreground 10 "✅ Gravatar config saved"

# === Confirm Start ===
echo ""
gum confirm "🚀 Ready to run all Glans modules?" || {
  echo "❌ Setup cancelled."
  exit 1
}

# === Run All Installers ===
echo ""
gum style --padding "0 2" --border normal --border-foreground 244 \
  "📦 Preparing modules from: $TARGET_DIR"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Directory not found: $TARGET_DIR"
  exit 1
fi

find "$TARGET_DIR" -maxdepth 1 -type f -name "*.sh" -executable | sort | while read -r script; do
  MODULE_NAME="$(basename "$script")"
  if $VERBOSE; then
    echo "▶️  Running: $MODULE_NAME"
    "$script" all
    echo "✅ Finished: $MODULE_NAME"
  else
    gum spin --spinner dot --title "Running $MODULE_NAME..." -- "$script" all >/dev/null
    gum style --foreground 10 "✔️  $MODULE_NAME finished"
  fi
done

# === Done ===
echo ""
gum style --border rounded --padding "1 4" --margin "1" \
  --foreground 10 --border-foreground 212 --align center \
  "🎉 Glans setup complete!" "" \
  "Your Debian Trixie system is now shiny and ready." "" \
  "🔁 Please reboot your system to apply all changes."
