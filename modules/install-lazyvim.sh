#!/bin/bash
set -e

MODULE_NAME="neovim"
CONFIG_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.config/nvim.bak"
ACTION="${1:-all}"

# === OS Detection ===
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Cannot detect operating system."
  exit 1
fi

install_deps() {
  echo "📦 Installing Neovim + build dependencies..."

  case "$OS_ID" in
    debian | ubuntu)
      DEPS=(
        neovim git curl unzip build-essential
        ripgrep fd-find fzf
        pkg-config ninja-build libtool autoconf automake gdb
      )
      sudo apt update
      sudo apt install -y "${DEPS[@]}"
      ;;
    fedora)
      DEPS=(
        neovim git curl unzip
        ripgrep fd-find fzf
        pkgconf-pkg-config ninja-build libtool autoconf automake gdb make
      )
      sudo dnf install -y "${DEPS[@]}"
      ;;
    *)
      echo "❌ Unsupported OS: $OS_ID"
      exit 1
      ;;
  esac

  echo "✅ Dependencies installed."
}

config_lazyvim() {
  echo "⚙️ Configuring LazyVim..."

  if [[ -d "$CONFIG_DIR" && ! -L "$CONFIG_DIR" ]]; then
    echo "🔄 Backing up existing config to $BACKUP_DIR"
    if [[ -d "$BACKUP_DIR" ]]; then
      BACKUP_DIR="$HOME/.config/nvim.bak_$(date +%Y%m%d%H%M%S)"
      echo "⚠️ Backup folder already exists. Creating: $BACKUP_DIR"
    fi
    mv "$CONFIG_DIR" "$BACKUP_DIR"
  fi

  echo "📁 Cloning LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$CONFIG_DIR"
  rm -rf "$CONFIG_DIR/.git"

  echo "🎨 Enabling Catppuccin theme..."
  mkdir -p "$CONFIG_DIR/lua/plugins"
  cat > "$CONFIG_DIR/lua/plugins/init.lua" <<EOF
return {
  { import = "lazyvim.plugins.extras.ui.catppuccin" },
}
EOF

  echo "🎨 Setting Catppuccin as default colorscheme..."
  mkdir -p "$CONFIG_DIR/lua/config"
  cat > "$CONFIG_DIR/lua/config/options.lua" <<EOF
vim.opt.termguicolors = true
vim.cmd.colorscheme("catppuccin")
EOF

  echo "🧠 Configuring Mason to auto-install LSPs..."
  cat > "$CONFIG_DIR/lua/plugins/mason-lsp.lua" <<EOF
return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "lua-language-server",
      "typescript-language-server",
      "pyright",
    },
  },
}
EOF

  echo "🔤 Setting Hack Nerd Font (if GUI supports)..."
  cat > "$CONFIG_DIR/lua/config/ui.lua" <<EOF
vim.opt.guifont = "Hack Nerd Font:h12"
EOF

  echo "🎨 Customizing dashboard header..."
  cat > "$CONFIG_DIR/lua/plugins/dashboard-header.lua" <<'EOF'
return {
  "nvimdev/dashboard-nvim",
  opts = function(_, opts)
    opts.config.header = {
      "      ▄▄▄▄    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▄▄▄▄      ",
      "   ▄████████▄  ▒ AFTER INSTALL ▒  ▄████████▄   ",
      " ▄███▀░▐█▌░▀███▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄███▀░▐█▌░▀███▄",
      "████▒░▒██▒░▒████▒  Neovim+Lazy  ████▒░▒██▒░▒████",
      "▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀",
    }
  end,
}
EOF

  echo "🎹 Adding keymap override..."
  cat > "$CONFIG_DIR/lua/config/keymaps.lua" <<EOF
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
EOF

  echo "✅ LazyVim fully configured."
  echo "🚀 Start Neovim and run :Lazy sync if needed."
}

clean_neovim() {
  echo "🧹 Removing Neovim and build tools..."

  case "$OS_ID" in
    debian | ubuntu)
      sudo apt purge -y neovim build-essential ripgrep fd-find fzf \
        pkg-config ninja-build libtool autoconf automake gdb || true
      sudo apt autoremove -y
      ;;
    fedora)
      sudo dnf remove -y neovim ripgrep fd-find fzf \
        pkgconf-pkg-config ninja-build libtool autoconf automake gdb make || true
      ;;
  esac

  rm -rf "$CONFIG_DIR" "$BACKUP_DIR"

  echo "✅ Clean complete."
}

# === Dispatcher ===
case "$ACTION" in
  deps) install_deps ;;
  install) install_deps ;;
  config) config_lazyvim ;;
  clean) clean_neovim ;;
  all)
    install_deps
    config_lazyvim
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
