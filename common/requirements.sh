#!/bin/bash
set -e

ensure_git_installed() {
  if ! command -v git &>/dev/null; then
    echo "🛠️ Git is not installed. Installing..."

    case "$ID" in
      debian|ubuntu)
        sudo apt update && sudo apt install -y git
        ;;
      fedora)
        sudo dnf install -y git
        ;;
      *)
        echo "❌ Cannot auto-install git on this OS. Please install it manually."
        exit 1
        ;;
    esac
  fi
}

ensure_gum_installed() {
  local required_version="${1:-0.14.3}"
  local current_version
  current_version="$(gum --version 2>/dev/null || echo "0.0.0")"

  # Compare versions: if required > current → reinstall
  if [[ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" != "$required_version" ]]; then
    echo "✨ Installing gum v$required_version (current: $current_version)..."

    case "$ID" in
      debian|ubuntu)
        local tmp_deb="/tmp/gum_${required_version}_amd64.deb"
        curl -fsSL -o "$tmp_deb" "https://github.com/charmbracelet/gum/releases/download/v${required_version}/gum_${required_version}_amd64.deb"
        sudo dpkg -i "$tmp_deb"
        rm "$tmp_deb"
        ;;
      fedora)
        sudo dnf install -y gum || {
          local tmp_rpm="/tmp/gum-${required_version}.rpm"
          curl -fsSL -o "$tmp_rpm" "https://github.com/charmbracelet/gum/releases/download/v${required_version}/gum-${required_version}-1.x86_64.rpm"
          sudo dnf install -y "$tmp_rpm"
          rm "$tmp_rpm"
        }
        ;;
      *)
        echo "❌ Cannot auto-install gum on this OS. Please install it manually."
        exit 1
        ;;
    esac
  fi
}
