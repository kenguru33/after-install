#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

MODULE_NAME="nvidia"
ACTION="${1:-all}"

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect OS."
  exit 1
fi

# === Skip if not Debian ===
if [[ "$OS_ID" != "debian" ]]; then
  echo "ℹ️ Skipping $MODULE_NAME: not a Debian system."
  exit 0
fi

# === Check for NVIDIA GPU ===
has_nvidia_gpu() {
  lspci | grep -i 'vga\|3d' | grep -iq nvidia
}

# === Dependencies ===
install_deps() {
  echo "🔧 Installing build dependencies..."
  sudo apt update
  sudo apt install -y dkms linux-headers-$(uname -r) firmware-misc-nonfree software-properties-common
  echo "✅ Dependencies installed."
}

# === Enable experimental repo ===
enable_experimental_repo() {
  echo "📦 Enabling experimental repository..."
  echo -e "\n# Experimental\ndeb http://deb.debian.org/debian experimental main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/experimental.list
  sudo apt update
}

# === Install NVIDIA driver ===
install_nvidia() {
  if ! has_nvidia_gpu; then
    echo "⚠️  No NVIDIA GPU detected. Skipping driver installation."
    return
  fi

  echo "🚀 Installing NVIDIA driver from experimental..."
  sudo apt -t experimental install -y nvidia-driver
  echo "✅ NVIDIA driver installed from experimental."
}

# === Configure NVIDIA (Wayland-specific hint) ===
config_nvidia() {
  echo "⚙️  Configuring NVIDIA..."
  echo "📝 For Wayland support, ensure KMS is enabled (usually default on modern systems)."
  echo "🔁 A reboot is required to complete the setup."
}

# === Clean installed NVIDIA packages ===
clean_nvidia() {
  echo "🧹 Removing NVIDIA driver..."
  sudo apt remove --purge -y nvidia-driver || true
  sudo apt autoremove -y
  echo "✅ NVIDIA driver removed."
}

# === Entry point ===
case "$ACTION" in
  deps)
    install_deps
    enable_experimental_repo
    ;;
  install)
    install_nvidia
    ;;
  config)
    config_nvidia
    ;;
  clean)
    clean_nvidia
    ;;
  all)
    install_deps
    enable_experimental_repo
    install_nvidia
    config_nvidia
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
