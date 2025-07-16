#!/bin/bash
set -e

MODULE_NAME="k8s-tools"
BIN_DIR="$HOME/.local/bin"
SRC_DIR="$HOME/.local/src/k8s-tools"
ACTION="${1:-all}"

# === Utility ===

has_apt_package() {
  apt-cache show "$1" &>/dev/null
}

ensure_bin_path() {
  local shell_rc
  mkdir -p "$BIN_DIR"

  if ! grep -q "$BIN_DIR" <<< "$PATH"; then
    if [[ "$SHELL" == */zsh ]]; then
      shell_rc="$HOME/.zshrc"
    else
      shell_rc="$HOME/.bashrc"
    fi
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$shell_rc"
    echo "✅ Added $BIN_DIR to PATH in $shell_rc"

    # Apply now
    export PATH="$BIN_DIR:$PATH"
    echo "🔄 PATH updated for current session"
  else
    echo "ℹ️ $BIN_DIR already in PATH"
  fi
}

install_deps() {
  echo "📦 Installing base build dependencies..."
  sudo apt update
  sudo apt install -y build-essential git curl unzip golang bash-completion
  mkdir -p "$SRC_DIR"
}

install_or_build_kubectl() {
  if has_apt_package kubectl; then
    echo "📦 Installing kubectl from APT..."
    sudo apt install -y kubectl
  else
    echo "🔧 Building kubectl from source (v1.30.0)..."
    cd "$SRC_DIR"
    [[ ! -d kubernetes ]] && git clone --depth 1 --branch v1.30.0 https://github.com/kubernetes/kubernetes
    cd kubernetes
    make kubectl
    cp _output/bin/kubectl "$BIN_DIR"
    echo "✅ kubectl built and installed to $BIN_DIR"
  fi
}

install_or_build_helm() {
  if has_apt_package helm; then
    echo "📦 Installing helm from APT..."
    sudo apt install -y helm
  else
    echo "🔧 Building helm from source (v3.14.0)..."
    cd "$SRC_DIR"
    [[ ! -d helm ]] && git clone --branch v3.14.0 https://github.com/helm/helm.git
    cd helm
    make
    cp bin/helm "$BIN_DIR"
    echo "✅ helm built and installed to $BIN_DIR"
  fi
}

install_kubectx() {
  if has_apt_package kubectx; then
    echo "📦 Installing kubectx and kubens from APT..."
    sudo apt install -y kubectx
  else
    echo "📁 Installing kubectx and kubens from source..."
    cd "$SRC_DIR"
    [[ ! -d kubectx ]] && git clone https://github.com/ahmetb/kubectx.git
    ln -sf "$SRC_DIR/kubectx/kubectx" "$BIN_DIR/kubectx"
    ln -sf "$SRC_DIR/kubectx/kubens" "$BIN_DIR/kubens"
    echo "✅ kubectx and kubens linked to $BIN_DIR"
  fi
}

setup_completion() {
  echo "🧠 Installing shell completions for kubectl and helm..."

  [[ -d /etc/bash_completion.d ]] || sudo mkdir -p /etc/bash_completion.d

  if command -v kubectl &>/dev/null; then
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  fi

  if command -v helm &>/dev/null; then
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
  fi

  echo "✅ Completions installed for kubectl and helm"
}

clean_all() {
  echo "🧹 Cleaning Kubernetes tools..."

  sudo apt purge -y kubectl helm kubectx || true
  sudo apt autoremove -y

  rm -f "$BIN_DIR/kubectl" "$BIN_DIR/helm"
  rm -f "$BIN_DIR/kubectx" "$BIN_DIR/kubens"
  rm -rf "$SRC_DIR"

  sudo rm -f /etc/bash_completion.d/kubectl /etc/bash_completion.d/helm

  echo "✅ Clean complete."
}

# === Main logic ===
case "$ACTION" in
  install)
    install_deps
    ensure_bin_path
    install_or_build_kubectl
    install_or_build_helm
    install_kubectx
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
    install_or_build_kubectl
    install_or_build_helm
    install_kubectx
    setup_completion
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [install|config|clean|all]"
    exit 1
    ;;
esac
