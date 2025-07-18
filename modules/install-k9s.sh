#!/bin/bash
set -e

MODULE_NAME="k9s"
ACTION="${1:-all}"

BIN_DIR="$HOME/.local/bin"
SRC_DIR="$HOME/.local/src/k9s"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect OS."
  exit 1
fi

# === Dependencies ===
DEPS_DEBIAN=(curl git golang)
DEPS_FEDORA=(curl git golang)

has_apt_package() {
  apt-cache show "$1" &>/dev/null
}

install_deps() {
  echo "📦 Installing dependencies for $OS_ID..."
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt update
    sudo apt install -y "${DEPS_DEBIAN[@]}"
  elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf install -y "${DEPS_FEDORA[@]}"
  else
    echo "❌ Unsupported OS: $OS_ID"
    exit 1
  fi
}

ensure_bin_path() {
  local shell_rc
  mkdir -p "$BIN_DIR"

  if ! grep -q "$BIN_DIR" <<< "$PATH"; then
    export PATH="$BIN_DIR:$PATH"
    echo "✅ Added $BIN_DIR to current PATH"

    shell_rc="$HOME/.zshrc"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$shell_rc"
    echo "✅ Added $BIN_DIR to PATH in $shell_rc"
  else
    echo "ℹ️ $BIN_DIR already in PATH"
  fi
}

install_or_build_k9s() {
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]] && has_apt_package k9s; then
    echo "📦 Installing k9s from APT..."
    sudo apt install -y k9s
  elif [[ "$OS_ID" == "fedora" ]]; then
    echo "📦 Installing k9s from Fedora..."
    sudo dnf install -y k9s
  else
    echo "🔧 Building k9s from source (v0.32.4)..."
    mkdir -p "$SRC_DIR"
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
  COMPLETION_DIR="$HOME/.oh-my-zsh/custom/completions"
  mkdir -p "$COMPLETION_DIR"

  if command -v k9s &>/dev/null; then
    k9s completion zsh > "$COMPLETION_DIR/k9s-completion.zsh"
  fi

  echo "source $COMPLETION_DIR/k9s-completion.zsh" >> "$HOME/.zshrc"
  echo "✅ Completion installed and sourced for k9s"
}

clean_all() {
  echo "🧹 Cleaning k9s..."
  if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    sudo apt purge -y k9s || true
    sudo apt autoremove -y
  elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf remove -y k9s || true
  fi

  rm -f "$BIN_DIR/k9s"
  rm -rf "$SRC_DIR"
  rm -f "$HOME/.oh-my-zsh/custom/completions/k9s-completion.zsh"
  echo "✅ Clean complete."
}

# === Entrypoint ===
case "$ACTION" in
  deps)
    install_deps
    ;;
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
    install_deps
    ensure_bin_path
    install_or_build_k9s
    setup_completion
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [deps|install|config|clean|all]"
    exit 1
    ;;
esac
