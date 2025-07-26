#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="nvidia"
ACTION="${1:-all}"
VERSION="570.172.08"
INSTALLER="NVIDIA-Linux-x86_64-${VERSION}.run"
URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${VERSION}/${INSTALLER}"
TMP_DIR="$(mktemp -d -t nvidia-dkms-XXXXXX)"
EXTRACT_DIR="${TMP_DIR}/extracted"

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

# === Disable Nouveau ===
disable_nouveau() {
  echo "🛑 Disabling Nouveau driver..."
  sudo bash -c 'cat > /etc/modprobe.d/disable-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF'
  sudo update-initramfs -u
}

# === Ensure nvidia-drm.modeset=1 in GRUB ===
configure_grub() {
  if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    echo "⚙️  Adding nvidia-drm.modeset=1 to GRUB..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="nvidia-drm.modeset=1 /' /etc/default/grub
    sudo update-grub
  fi
}

# === Install dependencies ===
install_deps() {
  echo "📦 Installing required packages..."
  sudo apt update
  sudo apt install -y build-essential dkms linux-headers-$(uname -r) gcc make curl
}

# === Install NVIDIA driver ===
install_driver() {
  echo "⬇️  Downloading NVIDIA driver $VERSION..."
  cd "$TMP_DIR"
  curl -fLO "$URL"
  chmod +x "$INSTALLER"

  if [[ -d "$EXTRACT_DIR" ]]; then
    echo "🧽 Cleaning up existing extraction dir..."
    rm -rf "$EXTRACT_DIR"
  fi

  echo "📦 Extracting installer..."
  ./"$INSTALLER" --extract-only --target "$EXTRACT_DIR"
  cd "$EXTRACT_DIR"

  echo "🔧 Installing driver with DKMS support..."
  sudo ./nvidia-installer \
    --silent \
    --dkms \
    --no-install-compat32-libs \
    --no-install-libglvnd || echo "⚠️ Installer returned warning."
}

# === Configure NVIDIA settings ===
config_driver() {
  echo "⚙️  Enabling NVIDIA memory preservation..."
  echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-power.conf
  sudo update-initramfs -u
}

# === Clean up everything ===
clean_driver() {
  echo "🧹 Removing NVIDIA driver..."
  sudo dkms remove nvidia/$VERSION --all || true
  sudo rm -f /etc/modprobe.d/nvidia-power.conf /etc/modprobe.d/disable-nouveau.conf
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
  install)
    install_deps
    disable_nouveau
    configure_grub
    install_driver
    config_driver
    echo "🔁 Reboot now to activate NVIDIA driver."
    ;;
  config) config_driver ;;
  clean) clean_driver ;;
  all)
    install_deps
    disable_nouveau
    configure_grub
    install_driver
    config_driver
    echo "🔁 Reboot now to activate NVIDIA driver."
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
