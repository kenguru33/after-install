#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="nvidia"
ACTION="${1:-all}"
TMP_DIR="$(mktemp -d -t nvidia-dkms-XXXXXX)"

# === Ensure Debian ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
    echo "⚠️  This script is for Debian only. Skipping."
    exit 0
  fi
else
  echo "❌ Cannot detect OS."
  exit 1
fi

# ✅ NVIDIA driver version (must be defined after sourcing os-release!)
VERSION="570.172.08"
INSTALLER="NVIDIA-Linux-x86_64-${VERSION}.run"
URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${VERSION}/${INSTALLER}"

# === Detect NVIDIA GPU and confirm with gum ===
if lspci | grep -qi 'nvidia'; then
  echo "🎮 NVIDIA GPU detected."
  if ! command -v gum &>/dev/null; then
    echo "❌ gum is not installed. Please install gum for interactive prompts."
    exit 1
  fi
  if ! gum confirm "Install NVIDIA driver version ${VERSION} using DKMS?"; then
    echo "❌ Installation canceled by user."
    exit 0
  fi
else
  echo "⚠️  No NVIDIA GPU detected. Skipping NVIDIA installation."
  exit 0
fi

# === Dependencies ===
install_deps() {
  echo "📦 Installing required packages..."
  sudo apt update
  sudo apt install -y build-essential dkms linux-headers-$(uname -r) gcc make curl
}

# === Driver install ===
install_driver() {
  echo "⬇️  Downloading NVIDIA driver $VERSION..."
  cd "$TMP_DIR"
  curl -fLO "$URL"

  chmod +x "$INSTALLER"

  echo "📦 Extracting installer..."
  ./"$INSTALLER" --extract-only --target "$TMP_DIR/$VERSION"

  cd "$TMP_DIR/$VERSION"

  echo "🔧 Installing driver with DKMS support..."
  sudo ./nvidia-installer \
    --silent \
    --dkms \
    --no-install-compat32-libs \
    --no-install-libglvnd || echo "⚠️ Installer returned warning."

  echo "✅ NVIDIA driver $VERSION installed."
}

# === Configuration ===
config_driver() {
  echo "⚙️  Enabling NVIDIA memory preservation..."
  echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-power.conf
  sudo update-initramfs -u
  echo "🔁 Please reboot to activate the driver."
}

# === Cleanup ===
clean_driver() {
  echo "🧹 Removing NVIDIA driver..."
  sudo dkms remove nvidia/$VERSION --all || true
  sudo rm -f /etc/modprobe.d/nvidia-power.conf
  sudo update-initramfs -u
  echo "✅ Driver removed. Manual reboot recommended."
}

# === Final cleanup ===
finish() {
  echo "🧽 Cleaning up temporary files..."
  rm -rf "$TMP_DIR"
}
trap finish EXIT

# === Entry point ===
case "$ACTION" in
  deps) install_deps ;;
  install) install_driver ;;
  config) config_driver ;;
  clean) clean_driver ;;
  all)
    install_deps
    install_driver
    config_driver
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
