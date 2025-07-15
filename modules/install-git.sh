#!/bin/bash
set -e

MODULE_NAME="git"
CONFIG_FILE="$HOME/.config/after-install/userinfo.config"
ACTION="${1:-all}"

# === Functions ===

install_git() {
  echo "📦 Installing Git..."
  sudo apt update
  sudo apt install -y git
}

configure_git() {
  echo "🛠️  Configuring Git..."

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

  editor=$(gum input --prompt "🖊️ Preferred editor (e.g. nano, vim, code): " --placeholder "nano")
  if [[ -z "$editor" ]]; then
    editor="nano"
  fi

  git config --global user.name "$name"
  git config --global user.email "$email"
  git config --global core.editor "$editor"
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global credential.helper store

  git config --global color.ui auto
  git config --global core.autocrlf input
  git config --global alias.st status
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.cm "commit -m"
  git config --global alias.hist "log --oneline --graph --decorate"

  echo "✅ Git configured for $name <$email>"
}

show_help() {
  echo "Usage: $0 [all|install|config]"
  echo ""
  echo "  all      Install and configure Git"
  echo "  install  Only install Git"
  echo "  config   Only configure Git settings"
}

# === Entry Point ===

case "$ACTION" in
  all)
    install_git
    configure_git
    ;;
  install)
    install_git
    ;;
  config)
    configure_git
    ;;
  *)
    show_help
    ;;
esac
