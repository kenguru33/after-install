#!/bin/bash
set -e
trap 'echo "❌ Git setup failed. Exiting." >&2' ERR

MODULE_NAME="git"
ACTION="${1:-all}"
CONFIG_FILE="$HOME/.config/after-install/userinfo.config"

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$REAL_USER")"
ZSH_CONFIG_DIR="$HOME_DIR/.zsh/config"
ZSH_TARGET_FILE="$ZSH_CONFIG_DIR/git.zsh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
DEPS=("git" "curl")

install_dependencies() {
  echo "🔧 Checking required dependencies..."

  if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    sudo apt update
    sudo apt install -y "${DEPS[@]}"
  elif [[ "$ID" == "fedora" ]]; then
    sudo dnf install -y "${DEPS[@]}"
  else
    echo "❌ Unsupported OS: $ID"
    exit 1
  fi
}

# === Load user config ===
load_user_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ User info config not found: $CONFIG_FILE"
    echo "💡 Run user-profile.sh first to set name and email."
    exit 1
  fi

  source "$CONFIG_FILE"

  if [[ -z "$name" || -z "$email" ]]; then
    echo "❌ Invalid user info in $CONFIG_FILE"
    exit 1
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
  sudo -u "$REAL_USER" git config --global init.defaultBranch main
  sudo -u "$REAL_USER" git config --global credential.helper store
  sudo -u "$REAL_USER" git config --global core.editor "nano"
  sudo -u "$REAL_USER" git config --global pull.rebase false
  sudo -u "$REAL_USER" git config --global color.ui auto
  sudo -u "$REAL_USER" git config --global core.autocrlf input

  sudo -u "$REAL_USER" git config --global alias.st status
  sudo -u "$REAL_USER" git config --global alias.co checkout
  sudo -u "$REAL_USER" git config --global alias.br branch
  sudo -u "$REAL_USER" git config --global alias.cm "commit -m"
  sudo -u "$REAL_USER" git config --global alias.hist "log --oneline --graph --decorate"

  echo "✅ Git configured for $name <$email>"
}

# === Install git-completion.zsh only ===
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

# === Copy static config ===
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

  echo "🧼 Removing Zsh config file and plugin..."
  rm -f "$ZSH_TARGET_FILE"
  rm -rf "$PLUGIN_DIR"

  echo "✅ Git config cleaned"
}

# === Help ===
show_help() {
  echo "Usage: $0 [all|deps|install|config|clean]"
  echo ""
  echo "  all      Install Git, configure user, setup shell completion"
  echo "  deps     Install required packages"
  echo "  install  Install Git only"
  echo "  config   Configure Git and shell integration"
  echo "  clean    Remove Git config and completions"
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
  clean)
    clean_git
    ;;
  *)
    show_help
    ;;
esac
