#!/bin/bash
set -e
trap 'echo "❌ Something went wrong. Exiting." >&2' ERR

# === Prompt for sudo early ===
sudo -v
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
USERNAME="${SUDO_USER:-$USER}"

install_zsh() {
  echo "🐚 Installing Zsh and dependencies..."
  sudo apt update
  sudo apt install -y zsh git curl wget unzip

  echo "✅ Zsh installed."

  echo "🔁 Setting shell to Zsh for user: $USERNAME"
  ZSH_PATH="$(command -v zsh)"
  sudo chsh -s "$ZSH_PATH" "$USERNAME"
  echo "✅ Shell for '$USERNAME' set to Zsh."
  echo "🔁 Please log out and back in or restart your terminal."
}

install_starship() {
  echo "🚀 Installing Starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  echo "✅ Starship installed."
}

configure_zsh() {
  echo "🧠 Installing Oh My Zsh..."

  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "🔌 Installing plugins..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

  echo "🧾 Updating .zshrc..."
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' ~/.zshrc || true
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' ~/.zshrc || true

  {
    echo 'fpath+=~/.oh-my-zsh/custom/plugins/zsh-completions/src'
    echo 'autoload -Uz compinit && compinit'
  } >> ~/.zshrc

  echo "✨ Enabling Starship in .zshrc..."
  if ! grep -q 'eval "$(starship init zsh)"' ~/.zshrc 2>/dev/null; then
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  fi

  echo "✅ Oh My Zsh configured."
}

clean_zsh() {
  echo "🧹 Removing Zsh configs and plugins..."
  rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zshenv ~/.zprofile ~/.zsh ~/.zcompdump* ~/.config/starship.toml

  echo "🔁 Switching shell back to Bash for user: $USERNAME"
  if command -v bash >/dev/null; then
    sudo chsh -s "$(command -v bash)" "$USERNAME"
    echo "✅ Shell for '$USERNAME' set to Bash."
    echo "🔁 Please log out and back in or restart your terminal."
  else
    echo "⚠️ Bash not found. Cannot change shell."
  fi

  echo "🧽 Uninstalling Zsh and Starship..."
  sudo apt remove --purge -y zsh
  sudo apt autoremove -y
  sudo rm -f /usr/local/bin/starship

  echo "✅ Zsh and related tools removed."
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install Zsh, Starship, plugins"
  echo "  install  Only install Zsh and set shell"
  echo "  config   Setup Oh My Zsh, plugins, Starship"
  echo "  clean    Remove Zsh, reset shell, delete config"
}

# === Entry Point ===
case "$1" in
  all)
    install_zsh
    install_starship
    configure_zsh
    ;;
  install)
    install_zsh
    ;;
  config)
    install_starship
    configure_zsh
    ;;
  clean)
    clean_zsh
    ;;
  *)
    show_help
    ;;
esac
