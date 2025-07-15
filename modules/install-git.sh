#!/bin/bash
set -e

MODULE_NAME="git"
CONFIG_FILE="$HOME/.config/after-install/userinfo.config"
ACTION="${1:-all}"

# === Load user config ===
load_user_config() {
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
}

# === Git Setup with Gum Progress ===
run_with_progress() {
  STEPS=6
  CURRENT=0

  PROGRESS_PIPE=$(mktemp -u)
  mkfifo "$PROGRESS_PIPE"

  gum progress --title "🔧 Installing and Configuring Git" \
               --spinner line --width 40 --value 0 < "$PROGRESS_PIPE" &
  PROGRESS_PID=$!

  {
    step() {
      CURRENT=$((CURRENT + 1))
      echo $((CURRENT * 100 / STEPS)) > "$PROGRESS_PIPE"
    }

    step; sudo apt update -y &>/dev/null
    step; sudo apt install -y git &>/dev/null
    step; git config --global user.name "$name" &>/dev/null
    step; git config --global user.email "$email" &>/dev/null
    step; git config --global init.defaultBranch main &>/dev/null
    step; git config --global credential.helper store &>/dev/null

    sleep 0.2
    rm "$PROGRESS_PIPE"
    wait "$PROGRESS_PID"
  } || {
    rm -f "$PROGRESS_PIPE"
    echo "❌ Git installation/config failed."
    exit 1
  }
}

# === Additional Git Config (Editor + Aliases) ===
extra_config() {
  editor=$(gum input --prompt "🖊️ Preferred editor (e.g. nano, vim, code): " --placeholder "nano")
  [[ -z "$editor" ]] && editor="nano"

  git config --global core.editor "$editor"
  git config --global pull.rebase false
  git config --global color.ui auto
  git config --global core.autocrlf input

  git config --global alias.st status
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.cm "commit -m"
  git config --global alias.hist "log --oneline --graph --decorate"
}

# === Entrypoints ===

install_git() {
  load_user_config
  run_with_progress
  extra_config
  echo "✅ Git configured for $name <$email>"
}

configure_git() {
  load_user_config
  extra_config
  echo "✅ Git reconfigured for $name <$email>"
}

clean_git() {
  echo "🗑️  Removing Git global config..."
  git config --global --unset-all user.name 2>/dev/null || true
  git config --global --unset-all user.email 2>/dev/null || true
  git config --global --remove-section alias 2>/dev/null || true
  git config --global --unset core.editor 2>/dev/null || true
  echo "✅ Git config cleaned"
}

show_help() {
  echo "Usage: $0 [all|install|config|clean]"
  echo ""
  echo "  all      Install and configure Git"
  echo "  install  Only install Git (with progress bar)"
  echo "  config   Only configure editor and aliases"
  echo "  clean    Remove Git global config"
}

# === Dispatch ===

case "$ACTION" in
  all)
    install_git
    ;;
  install)
    install_git
    ;;
  config)
    configure_git
    ;;
  clean)
    clean_git
    ;;
  *)
    show_help
    ;;
esac
