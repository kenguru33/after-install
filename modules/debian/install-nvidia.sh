#!/bin/bash
set -e
trap 'echo "❌ NVIDIA CUDA driver installation failed. Exiting." >&2' ERR

MODULE_NAME="nvidia-cuda"
ACTION="${1:-all}"

# === Detect OS Version and Set DISTRO ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "$VERSION_CODENAME" in
    trixie)
      DISTRO="debian12" # Fallback until NVIDIA provides debian13 repo
      ;;
    *)
      DISTRO="$VERSION_CODENAME"
      ;;
  esac
else
  echo "❌ Cannot detect OS version."
  exit 1
fi

ARCH="x86_64"
KEYRING_PKG="cuda-keyring_1.1-1_all.deb"
KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/${KEYRING_PKG}"
REPO_LIST="/etc/apt/sources.list.d/cuda-${DISTRO}-${ARCH}.list"
ALT_KEY_URL="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-archive-keyring.gpg"
ALT_KEY_PATH="/usr/share/keyrings/cuda-archive-keyring.gpg"

# === Step: deps ===
deps() {
  echo "📦 Installing prerequisites..."
  sudo apt update
  sudo apt install -y wget gnupg linux-headers-$(uname -r)
}

# === Step: preconfig ===
preconfig() {
  echo "🔑 Downloading NVIDIA CUDA keyring..."

  if wget -q "$KEYRING_URL"; then
    echo "📥 Installing keyring package..."
    sudo dpkg -i "$KEYRING_PKG"
    rm -f "$KEYRING_PKG"
  else
    echo "⚠️ Fallback: Installing GPG key manually..."
    wget -q "$ALT_KEY_URL" -O cuda-archive-keyring.gpg
    sudo mv cuda-archive-keyring.gpg "$ALT_KEY_PATH"
    echo "📄 Adding CUDA APT repository..."
    echo "deb [signed-by=$ALT_KEY_PATH] https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/ /" \
      | sudo tee "$REPO_LIST" > /dev/null
  fi

  echo "🔄 Updating package lists..."
  sudo apt update
}

# === Step: install ===
install() {
  echo "💠 Installing proprietary CUDA driver..."
  sudo apt -V install -y cuda-drivers
}

# === Step: config ===
config() {
  echo "🔧 Enabling Wayland in GDM3..."

  GDM_CONF="/etc/gdm3/daemon.conf"
  if sudo grep -q "^#WaylandEnable=false" "$GDM_CONF"; then
    sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=true/' "$GDM_CONF"
  elif sudo grep -q "^WaylandEnable=false" "$GDM_CONF"; then
    sudo sed -i 's/^WaylandEnable=false/WaylandEnable=true/' "$GDM_CONF"
  elif ! sudo grep -q "^WaylandEnable=" "$GDM_CONF"; then
    sudo sed -i '/^\[daemon\]/a WaylandEnable=true' "$GDM_CONF"
  fi

  echo "🛡️ Overriding NVIDIA udev rule to keep Wayland enabled..."
  RULE_PATH="/etc/udev/rules.d/99-nvidia-wayland.rules"
  sudo tee "$RULE_PATH" > /dev/null <<EOF
# Allow Wayland with NVIDIA by overriding upstream rule
ENV{NVIDIA_DRIVER_CAPABILITIES}="all"
EOF

  echo "🔃 Reloading udev rules..."
  sudo udevadm control --reload-rules
  sudo udevadm trigger

  echo "🔁 Please reboot your system to apply GDM + Wayland + NVIDIA changes."
}

# === Step: clean ===
clean() {
  echo "🧹 Cleaning up NVIDIA APT sources and keyrings..."
  sudo rm -f "$REPO_LIST" "$ALT_KEY_PATH"
  sudo apt update
}

# === Entrypoint ===
case "$ACTION" in
  all)
    deps
    preconfig
    install
    config
    ;;
  deps) deps ;;
  preconfig) preconfig ;;
  install) install ;;
  config) config ;;
  clean) clean ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|preconfig|install|config|clean]"
    exit 1
    ;;
esac
