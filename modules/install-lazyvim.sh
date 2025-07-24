#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

ACTION="${1:-install}"
timestamp="$(date +%Y%m%d%H%M%S)"

# === OS Detection ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Cannot detect OS."
  exit 1
fi

install_deps() {
  echo "📦 Installing Neovim and related tools..."
  case "$OS_ID" in
    debian | ubuntu)
      sudo apt update
      sudo apt install -y neovim git curl unzip ripgrep fd-find fzf
      ;;
    fedora)
      sudo dnf install -y neovim git curl unzip ripgrep fd-find fzf
      ;;
    *)
      echo "❌ Unsupported OS: $OS_ID"
      exit 1
      ;;
  esac
}

backup_and_clone_lazyvim() {
  echo "📁 Backing up any existing Neovim config..."

  for dir in ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
    if [[ -e "$dir" ]]; then
      mv "$dir" "${dir}.bak-${timestamp}"
      echo "🔄 Moved $dir → ${dir}.bak-${timestamp}"
    fi
  done

  echo "📥 Cloning LazyVim starter..."
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git

  echo "✅ LazyVim is installed."
  echo "🚀 Run 'nvim' and then :Lazy sync to complete setup."
}

clean_lazyvim() {
  echo "🧹 Removing Neovim config and related data..."
  rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
  echo "✅ LazyVim removed."

  echo "📦 Optionally remove Neovim and tools..."
  read -rp "Uninstall Neovim and tools? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    case "$OS_ID" in
      debian | ubuntu)
        sudo apt purge -y neovim ripgrep fd-find fzf
        sudo apt autoremove -y
        ;;
      fedora)
        sudo dnf remove -y neovim ripgrep fd-find fzf
        ;;
    esac
    echo "✅ Packages removed."
  fi
}

# === Dispatcher ===
case "$ACTION" in
  install)
    install_deps
    backup_and_clone_lazyvim
    ;;
  clean)
    clean_lazyvim
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [install|clean]"
    exit 1
    ;;
esac
