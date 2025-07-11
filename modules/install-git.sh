#!/bin/bash
set -e

# === Functions ===

install_git() {
  echo "📦 Installing Git..."
  sudo apt update
  sudo apt install -y git
}

configure_git() {
  echo "🛠️  Configuring Git..."

  read -p "📝 Enter your full name: " name
  read -p "📧 Enter your email address: " email
  read -p "🖊️  Preferred editor (e.g. nano, vim, code, nvim): " editor

  git config --global user.name "$name"
  git config --global user.email "$email"
  git config --global core.editor "$editor"
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global credential.helper store

  # Optional aliases and extras
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

case "$1" in
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
