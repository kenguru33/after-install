#!/bin/bash
set -e

MODULE_NAME="k9s"
BIN_DIR="$HOME/.local/bin"
SRC_DIR="$HOME/.local/src/k9s"
ACTION="${1:-all}"

# === Utility ===
has_apt_package() {
  apt-cache show "$1" &>/dev/null
}

ensure_bin_path() {
  local shell_rc
  mkdir -p "$BIN_DIR"

  # Check if $BIN_DIR is already in PATH
  if ! grep -q "$BIN_DIR" <<< "$PATH"; then
    # Add to the shell session immediately
    export PATH="$BIN_DIR:$PATH"
    echo "✅ Added $BIN_DIR to current PATH"

    # Now ensure it's in .zshrc for persistence
    shell_rc="$HOME/.zshrc"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$shell_rc"
    echo "✅ Added $BIN_DIR to PATH in $shell_rc"
  else
    echo "ℹ️ $BIN_DIR already in PATH"
  fi
}

install_or_build_k9s() {
  if has_apt_package k9s; then
    echo "📦 Installing k9s from APT..."
    sudo apt install -y k9s
  else
    echo "🔧 Building k9s from source (v0.32.4)..."
    mkdir -p "$SRC_DIR"  # Create the source directory if it doesn't exist
    cd "$SRC_DIR"
    [[ ! -d k9s ]] && git clone --branch v0.32.4 https://github.com/derailed/k9s.git
    cd k9s
    go install
    cp "$HOME/go/bin/k9s" "$BIN_DIR"
    echo "✅ k9s built and installed to $BIN_DIR"
  fi
}

setup_completion() {
  echo "🧠 Installing shell completions for k9s..."

  # Ensure Oh My Zsh custom completions path is used
  COMPLETION_DIR="$HOME/.oh-my-zsh/custom/completions"
  mkdir -p "$COMPLETION_DIR"

  if command -v k9s &>/dev/null; then
    k9s completion zsh > "$COMPLETION_DIR/k9s-completion.zsh"
  fi

  # Source the completion script in the user's shell config
  SHELL_RC="$HOME/.zshrc"
  echo "source $COMPLETION_DIR/k9s-completion.zsh" >> "$SHELL_RC"
  echo "✅ Completion installed and sourced for k9s"
}

clean_all() {
  echo "🧹 Cleaning up k9s..."

  sudo apt purge -y k9s || true
  sudo apt autoremove -y

  rm -f "$BIN_DIR/k9s"
  rm -rf "$SRC_DIR"
  rm -f "$HOME/.oh-my-zsh/custom/completions/k9s-completion.zsh"

  echo "✅ Clean complete."
}

# === Main logic ===
case "$ACTION" in
  install)
    ensure_bin_path
    install_or_build_k9s
    ;;
  config)
    setup_completion
    ;;
  clean)
    clean_all
    ;;
  all)
    ensure_bin_path
    install_or_build_k9s
    setup_completion
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|install|config|clean]"
    exit 1
    ;;
esac
