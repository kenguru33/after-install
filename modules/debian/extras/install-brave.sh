#!/bin/bash
set -e

MODULE_NAME="brave-browser"
ACTION="${1:-all}"
RECONFIGURE=false

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect operating system."
  exit 1
fi

if [[ "$OS_ID" != "debian" && "$OS_ID" != "ubuntu" ]]; then
  echo "❌ This script only supports Debian or Ubuntu."
  exit 1
fi

# === Dependencies ===
DEPS=(curl gnupg apt-transport-https desktop-file-utils)

install_deps() {
  echo "📦 Installing system dependencies..."
  sudo apt update
  sudo apt install -y "${DEPS[@]}"

  echo "🔐 Adding Brave APT key and sources file (as per official docs)..."
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

  sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
}

install_brave() {
  echo "📦 Installing Brave Browser..."
  sudo apt update
  sudo apt install -y brave-browser
  echo "✅ Brave installed."
}

config_brave() {
  echo "⚙️  Configuring Brave for Wayland and NVIDIA..."

  local WRAPPER="$HOME/.local/bin/brave-wayland"
  local WAYLAND_DESKTOP="$HOME/.local/share/applications/brave-browser-wayland.desktop"
  local OVERRIDE_DESKTOP="$HOME/.local/share/applications/brave-browser.desktop"
  local SYSTEM_DESKTOP="/usr/share/applications/brave-browser.desktop"

  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

  # Detect NVIDIA
  local HAS_NVIDIA=false
  if lspci | grep -i nvidia &>/dev/null; then
    HAS_NVIDIA=true
    echo "⚠️  NVIDIA GPU detected — enabling __GLX_VENDOR_LIBRARY_NAME=nvidia"
  fi

  if [[ "$RECONFIGURE" = true || ! -f "$WRAPPER" ]]; then
    echo "🛠 Creating Brave Wayland wrapper: $WRAPPER"
    cat > "$WRAPPER" <<EOF
#!/bin/bash
${HAS_NVIDIA:+export __GLX_VENDOR_LIBRARY_NAME=nvidia}
exec /usr/bin/brave-browser --ozone-platform=wayland "\$@"
EOF
    chmod +x "$WRAPPER"
  else
    echo "✅ Wrapper already exists: $WRAPPER"
  fi

  if [[ "$RECONFIGURE" = true || ! -f "$WAYLAND_DESKTOP" ]]; then
    echo "🖼 Creating Wayland launcher: $WAYLAND_DESKTOP"
    cat > "$WAYLAND_DESKTOP" <<EOF
[Desktop Entry]
Name=Brave Browser (Wayland)
Exec=$WRAPPER %U
Icon=brave-browser
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
  else
    echo "✅ Wayland desktop launcher already exists."
  fi

  if [[ "$RECONFIGURE" = true || ! -f "$OVERRIDE_DESKTOP" ]]; then
    if [[ -f "$SYSTEM_DESKTOP" ]]; then
      echo "🙈 Hiding system Brave launcher by overriding: $OVERRIDE_DESKTOP"
      echo "[Desktop Entry]
Hidden=true" > "$OVERRIDE_DESKTOP"
    fi
  else
    echo "✅ Default launcher already hidden."
  fi

  echo "🔃 Updating desktop database..."
  update-desktop-database "$HOME/.local/share/applications"

  echo "✅ Brave is now configured for Wayland and NVIDIA."
}

clean_brave() {
  echo "🧹 Uninstalling Brave and cleaning up..."
  sudo apt remove -y brave-browser || true
  sudo apt autoremove -y
  sudo rm -f /etc/apt/sources.list.d/brave-browser-release.sources
  sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
  rm -f "$HOME/.local/bin/brave-wayland"
  rm -f "$HOME/.local/share/applications/brave-browser.desktop"
  rm -f "$HOME/.local/share/applications/brave-browser-wayland.desktop"
  update-desktop-database "$HOME/.local/share/applications"
  echo "✅ Brave fully removed."
}

# === Main entry point ===
if [[ "$2" == "--reconfigure" ]]; then
  RECONFIGURE=true
fi

case "$ACTION" in
  deps)
    install_deps
    ;;
  install)
    install_brave
    ;;
  config)
    config_brave
    ;;
  clean)
    clean_brave
    ;;
  all)
    install_deps
    install_brave
    config_brave
    ;;
  *)
    echo "Usage: $0 {deps|install|config|clean|all} [--reconfigure]"
    exit 1
    ;;
esac
