#!/bin/bash
set -e
trap 'echo "❌ Git setup failed. Exiting." >&2' ERR

MODULE_NAME="git"
ACTION="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_DIR="$HOME/.config/after-install"
CONFIG_FILE="$CONFIG_DIR/user-git-info.config"

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$REAL_USER")"
ZSH_CONFIG_DIR="$HOME_DIR/.zsh/config"
ZSH_TARGET_FILE="$ZSH_CONFIG_DIR/git.zsh"
PLUGIN_DIR="$HOME_DIR/.zsh/plugins/git"
FALLBACK_COMPLETION="$PLUGIN_DIR/git-completion.zsh"
TEMPLATE_FILE="$SCRIPT_DIR/config/git.zsh"

# === OS Detection ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi

# === Dependencies ===
DEPS=("git" "curl" "gum")

install_dependencies() {
  echo "🔧 Checking required dependencies..."
  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt update
    sudo apt install -y "${DEPS[@]}"
  else
    echo "❌ Unsupported OS: $ID. Only Debian-based systems are supported."
    exit 1
  fi
}

# === Prompt user for Git info ===
prompt_user_info() {
  echo "🔧 Prompting for Git user info..."
  mkdir -p "$CONFIG_DIR"

  while true; do
    name=$(gum input --prompt "📝 Full name:" --placeholder "John Doe")
    [[ -z "$name" ]] && gum style --foreground 1 "❌ Name cannot be empty." && continue
    break
  done

  while true; do
    email=$(gum input --prompt "📧 Email address:" --placeholder "john@example.com")
    if [[ -z "$email" ]]; then
      gum style --foreground 1 "❌ Email cannot be empty."
    elif [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      break
    else
      gum style --foreground 1 "❌ Invalid email format."
    fi
  done

  default_branch=$(gum input --prompt "🌿 Default branch:" --placeholder "main" --value "main")
  editor=$(gum input --prompt "📝 Default Git editor:" --placeholder "nvim" --value "nvim")

  if gum confirm "🔃 Enable 'git pull --rebase'?"; then
    pull_rebase="true"
  else
    pull_rebase="false"
  fi

  # Show summary
  gum style --border normal --margin "1" --padding "1" --foreground 2 <<EOF
✅ Git User Configuration:
   Name:            $name
   Email:           $email
   Default Branch:  $default_branch
   Editor:          $editor
   Pull Rebase:     $pull_rebase
EOF

  echo "name=\"$name\"" > "$CONFIG_FILE"
  echo "email=\"$email\"" >> "$CONFIG_FILE"
  echo "editor=\"$editor\"" >> "$CONFIG_FILE"
  echo "default_branch=\"$default_branch\"" >> "$CONFIG_FILE"
  echo "pull_rebase=\"$pull_rebase\"" >> "$CONFIG_FILE"
  echo "✅ Saved config to $CONFIG_FILE"
}

# === Load or prompt config ===
load_user_config() {
  if [[ "$ACTION" == "reconfigure" || ! -f "$CONFIG_FILE" ]]; then
    prompt_user_info
  fi

  source "$CONFIG_FILE"

  if [[ -z "$name" || -z "$email" ]]; then
    gum style --foreground 1 "❌ Config incomplete. Re-prompting..."
    prompt_user_info
    source "$CONFIG_FILE"
  fi
}

# === Git Installation ===
install_git_package() {
  echo "📦 Ensuring Git is installed..."
  if ! command -v git &>/dev/null; then
    install_dependencies
  else
    echo "✅ Git is already installed."
  fi
}

# === Git Configuration ===
configure_git() {
  echo "🛠️  Configuring Git..."

  sudo -u "$REAL_USER" git config --global user.name "$name"
  sudo -u "$REAL_USER" git config --global user.email "$email"
  sudo -u "$REAL_USER" git config --global init.defaultBranch "$default_branch"
  sudo -u "$REAL_USER" git config --global credential.helper store
  sudo -u "$REAL_USER" git config --global core.editor "$editor"
  sudo -u "$REAL_USER" git config --global pull.rebase "$pull_rebase"
  sudo -u "$REAL_USER" git config --global color.ui auto
  sudo -u "$REAL_USER" git config --global core.autocrlf input

  sudo -u "$REAL_USER" git config --global alias.st status
  sudo -u "$REAL_USER" git config --global alias.co checkout
  sudo -u "$REAL_USER" git config --global alias.br branch
  sudo -u "$REAL_USER" git config --global alias.cm "commit -m"
  sudo -u "$REAL_USER" git config --global alias.hist "log --oneline --graph --decorate"

  echo "✅ Git configured for $name <$email>"
}

# === Install git-completion.zsh ===
install_git_completion_zsh() {
  if [[ ! -f "$FALLBACK_COMPLETION" ]]; then
    echo "📥 Downloading git-completion.zsh fallback..."
    mkdir -p "$PLUGIN_DIR"
    curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh \
      -o "$FALLBACK_COMPLETION"
    chown -R "$REAL_USER:$REAL_USER" "$PLUGIN_DIR"
    echo "✅ Installed fallback: $FALLBACK_COMPLETION"
  else
    echo "⏭️  git-completion.zsh already present"
  fi
}

# === Copy Zsh config ===
config_git_shell() {
  echo "📄 Installing config/git.zsh from template..."
  mkdir -p "$ZSH_CONFIG_DIR"
  cp "$TEMPLATE_FILE" "$ZSH_TARGET_FILE"
  chown "$REAL_USER:$REAL_USER" "$ZSH_TARGET_FILE"
  echo "✅ Installed $ZSH_TARGET_FILE"
}

# === Clean Git Config ===
clean_git() {
  echo "🧹 Removing Git global config..."
  sudo -u "$REAL_USER" git config --global --unset-all user.name 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global --unset-all user.email 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global --remove-section alias 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global --unset core.editor 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global --unset init.defaultBranch 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global --unset pull.rebase 2>/dev/null || true

  echo "🧼 Removing Zsh config file and plugin..."
  rm -f "$ZSH_TARGET_FILE"
  rm -rf "$PLUGIN_DIR"

  echo "✅ Git config cleaned"
}

# === Help ===
show_help() {
  echo "Usage: $0 [all|deps|install|config|reconfigure|clean]"
  echo ""
  echo "  all          Install Git, configure user, setup shell completion"
  echo "  deps         Install required packages"
  echo "  install      Install Git only"
  echo "  config       Configure Git and shell integration (skips install)"
  echo "  reconfigure  Force prompt for Git user info and reapply config"
  echo "  clean        Remove Git config and completions"
}

# === Entry Point ===
case "$ACTION" in
  all)
    load_user_config
    install_git_package
    configure_git
    install_git_completion_zsh
    config_git_shell
    ;;
  deps)
    install_dependencies
    ;;
  install)
    install_git_package
    ;;
  config)
    load_user_config
    configure_git
    install_git_completion_zsh
    config_git_shell
    ;;
  reconfigure)
    ACTION="reconfigure"
    load_user_config
    configure_git
    install_git_completion_zsh
    config_git_shell
    ;;
  clean)
    clean_git
    ;;
  *)
    show_help
    ;;
esac
