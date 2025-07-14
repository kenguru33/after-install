#!/bin/bash
set -e

# === Metadata ===
SCRIPT_NAME="install-zellij.sh"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
ZELLIJ_CONFIG_FILE="$ZELLIJ_CONFIG_DIR/config.kdl"
ZELLIJ_BIN="$HOME/.local/bin/zellij"
ZSHRC_FILE="$HOME/.zshrc"

# === Install Zellij from GitHub ===
install() {
  echo "📦 Installing Zellij..."

  mkdir -p ~/.local/bin

  if command -v zellij >/dev/null || [[ -x "$ZELLIJ_BIN" ]]; then
    echo "✔️ Zellij already installed."
    return
  fi

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
  esac

  echo "🌐 Fetching latest release URL from GitHub..."
  URL=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest \
    | grep "browser_download_url" \
    | grep "linux-${ARCH}.tar.gz" \
    | cut -d '"' -f 4)

  if [[ -z "$URL" ]]; then
    echo "⚠️ GitHub API failed. Falling back to v0.39.2..."
    URL="https://github.com/zellij-org/zellij/releases/download/v0.39.2/zellij-${ARCH}-unknown-linux-musl.tar.gz"
  fi

  echo "⬇️ Downloading Zellij from: $URL"
  curl -Lo /tmp/zellij.tar.gz "$URL"
  tar -xzf /tmp/zellij.tar.gz -C /tmp
  mv /tmp/zellij "$ZELLIJ_BIN"
  chmod +x "$ZELLIJ_BIN"

  echo "✅ Zellij installed to $ZELLIJ_BIN"
  echo "👉 Make sure $HOME/.local/bin is in your PATH"
}

# === Configure Zellij with Catppuccin Mocha theme ===
config() {
  echo "⚙️ Writing Zellij config..."
  mkdir -p "$ZELLIJ_CONFIG_DIR"

  cat > "$ZELLIJ_CONFIG_FILE" <<EOF
theme "catppuccin-mocha"

themes {
  catppuccin-mocha {
    fg "#cdd6f4"
    bg "#1e1e2e"
    black "#45475a"
    red "#f38ba8"
    green "#a6e3a1"
    yellow "#f9e2af"
    blue "#89b4fa"
    magenta "#f5c2e7"
    cyan "#94e2d5"
    white "#bac2de"
    orange "#fab387"
  }
}

default_layout "compact"
default_mode "normal"
EOF

  echo "✅ Zellij theme set to Catppuccin Mocha"

  # === Inject into .zshrc ===
  if [[ -f "$ZSHRC_FILE" ]] && grep -q "exec zellij" "$ZSHRC_FILE"; then
    echo "ℹ️ Zellij already set in $ZSHRC_FILE"
  else
    echo "🔧 Adding Zellij autostart to $ZSHRC_FILE"
    cat >> "$ZSHRC_FILE" <<'EORC'

# === Auto-start Zellij if not already inside ===
if [ -z "$ZELLIJ" ] && [ -z "$TMUX" ] && [ -n "$PS1" ] && [ -t 1 ]; then
  command -v zellij >/dev/null && exec zellij
fi
EORC
    echo "✅ Zellij autostart added to $ZSHRC_FILE"
  fi
}

# === Clean config and binary ===
clean() {
  echo "🧹 Removing Zellij config and binary..."

  [[ -d "$ZELLIJ_CONFIG_DIR" ]] && rm -rf "$ZELLIJ_CONFIG_DIR" && echo "🗑️ Removed config: $ZELLIJ_CONFIG_DIR"
  [[ -f "$ZELLIJ_BIN" ]] && rm -f "$ZELLIJ_BIN" && echo "🗑️ Removed binary: $ZELLIJ_BIN"

  # Optional: remove from .zshrc
  if grep -q "# === Auto-start Zellij" "$ZSHRC_FILE"; then
    sed -i '/# === Auto-start Zellij/,/fi/d' "$ZSHRC_FILE"
    echo "🗑️ Removed Zellij autostart from $ZSHRC_FILE"
  fi
}

# === Run all ===
all() {
  install
  config
}

# === Entry Point ===
case "$1" in
  install) install ;;
  config) config ;;
  clean) clean ;;
  all|"") all ;;
  *)
    echo "Usage: $SCRIPT_NAME [all|install|config|clean]"
    exit 1
    ;;
esac
