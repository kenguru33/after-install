#!/bin/bash
set -e
trap 'echo "❌ Zsh env setup failed. Exiting." >&2' ERR

MODULE_NAME="zsh-env"
ACTION="${1:-all}"
REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$REAL_USER")"
PLUGIN_DIR="$HOME_DIR/.zsh/plugins"
LOCAL_BIN="$HOME_DIR/.local/bin"

declare -A PLUGINS=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
)

declare -A COMPLETIONS=(
  ["git"]="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
  ["kubectl"]="DYNAMIC"
  ["docker"]="DYNAMIC"
  ["helm"]="DYNAMIC"
  ["terraform"]="DYNAMIC"
  ["kubectx"]="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/_kubectx.zsh"
  ["kubens"]="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/_kubens.zsh"
)

# === Step: deps ===
deps() {
  echo "📦 Installing dependencies..."
  sudo apt update
  sudo apt install -y zsh git curl unzip fzf bat eza fd-find neovim

  echo "🛠 Ensuring $LOCAL_BIN exists..."
  mkdir -p "$LOCAL_BIN"
  chown "$REAL_USER:$REAL_USER" "$LOCAL_BIN"

  # Symlink fdfind → fd if needed
  if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
    ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
    echo "✅ Linked fdfind → fd"
  fi

  # Symlink batcat → bat if needed
  if command -v batcat >/dev/null && ! command -v bat >/dev/null; then
    ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
    echo "✅ Linked batcat → bat"
  fi
}

# === Step: install ===
install() {
  echo "🔌 Installing Zsh plugins into $PLUGIN_DIR..."
  mkdir -p "$PLUGIN_DIR"

  for name in "${!PLUGINS[@]}"; do
    repo="${PLUGINS[$name]}"
    dir="$PLUGIN_DIR/$name"
    if [[ -d "$dir" ]]; then
      echo "⏭️  $name already installed"
    else
      git clone --depth=1 "$repo" "$dir"
      echo "✅ Installed $name"
    fi
  done

  echo "🧠 Installing completions into $PLUGIN_DIR..."
  for name in "${!COMPLETIONS[@]}"; do
    dir="$PLUGIN_DIR/$name"
    mkdir -p "$dir"

    if [[ "${COMPLETIONS[$name]}" == "DYNAMIC" ]]; then
      file="$dir/$name.zsh"
      if command -v "$name" >/dev/null 2>&1; then
        echo "📄 Generating $name completion..."
        case "$name" in
          kubectl)   "$name" completion zsh > "$file" ;;
          docker)    "$name" completion zsh > "$file" ;;
          helm)      "$name" completion zsh > "$file" ;;
          terraform) "$name" completion zsh > "$file" ;;
          *) echo "❌ Unknown dynamic completion for $name"; continue ;;
        esac
        echo "✅ Created $file"
      else
        echo "⚠️  Skipping $name: CLI not installed"
      fi
    else
      url="${COMPLETIONS[$name]}"
      file="$dir/${url##*/}"
      if [[ ! -f "$file" ]]; then
        echo "📥 Downloading $name completion..."
        curl -fsSL "$url" -o "$file"
        echo "✅ Installed $file"
      else
        echo "⏭️  $name already present"
      fi
    fi
  done

  echo "🔐 Securing ~/.kube config files..."
  KUBE_DIR="$HOME_DIR/.kube"
  if [[ -d "$KUBE_DIR" ]]; then
    find "$KUBE_DIR" -type f -readable | while read -r file; do
      perms=$(stat -c "%a" "$file")
      if [[ "$perms" != "600" ]]; then
        echo "🔧 Fixing $file (was $perms)"
        chmod 600 "$file"
        chown "$REAL_USER:$REAL_USER" "$file"
      fi
    done
  fi

  if [[ -n "$KUBECONFIG" && -f "$KUBECONFIG" ]]; then
    perms=$(stat -c "%a" "$KUBECONFIG")
    if [[ "$perms" != "600" ]]; then
      echo "🔧 Fixing \$KUBECONFIG at $KUBECONFIG (was $perms)"
      chmod 600 "$KUBECONFIG"
      chown "$REAL_USER:$REAL_USER" "$KUBECONFIG"
    fi
  fi

  if [[ ! -x "$LOCAL_BIN/starship" ]]; then
    echo "🚀 Installing Starship prompt..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$LOCAL_BIN"
    chown "$REAL_USER:$REAL_USER" "$LOCAL_BIN/starship"
  else
    echo "⏭️  Starship already installed"
  fi

  echo "🛠 Ensuring Zsh is default shell for $REAL_USER..."
  if [[ "$(getent passwd "$REAL_USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    sudo chsh -s "$(command -v zsh)" "$REAL_USER"
    echo "✅ Default shell set to Zsh (log out and back in to activate)"
  else
    echo "⏭️  Zsh is already the default shell"
  fi
}

# === Step: config ===
config() {
  echo "🔧 Configuring .zshrc..."

  USER_HOME="$(eval echo "~$REAL_USER")"
  ZSHRC="$USER_HOME/.zshrc"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ZSHRC_TEMPLATE="$SCRIPT_DIR/config/zshrc"

  echo "📂 REAL_USER = $REAL_USER"
  echo "📂 USER_HOME = $USER_HOME"
  echo "📄 ZSHRC = $ZSHRC"
  echo "📄 TEMPLATE = $ZSHRC_TEMPLATE"

  if [[ -f "$ZSHRC" ]]; then
    timestamp="$(date +%Y%m%d%H%M%S)"
    backup="$ZSHRC.backup.$timestamp"
    cp "$ZSHRC" "$backup"
    echo "💾 Existing .zshrc backed up to:"
    echo "   $backup"
    cp "$ZSHRC_TEMPLATE" "$ZSHRC"
    echo "✅ .zshrc replaced from template"
  else
    cp "$ZSHRC_TEMPLATE" "$ZSHRC"
    echo "✅ .zshrc created from template"
  fi

  chown "$REAL_USER:$REAL_USER" "$ZSHRC"
}

# === Step: clean ===
clean() {
  echo "🧹 Cleaning Zsh environment..."

  echo "❌ Removing plugins from $PLUGIN_DIR"
  rm -rf "$PLUGIN_DIR"

  echo "❌ Removing starship binary from $LOCAL_BIN"
  rm -f "$LOCAL_BIN/starship"

  echo "❌ Removing symlinks for fd and bat"
  rm -f "$LOCAL_BIN/fd" "$LOCAL_BIN/bat"

  echo "❌ Removing .zshrc"
  rm -f "$HOME_DIR/.zshrc"

  echo "✅ Clean complete."
}

# === Entry Point ===
case "$ACTION" in
  all)    deps; install; config ;;
  deps)   deps ;;
  install) install ;;
  config) config ;;
  clean)  clean ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
