#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

# === Ensure we are on Debian ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
    echo "⚠️  This script is for Debian only. Skipping execution."
    exit 0
  fi
else
  echo "❌ Cannot detect OS. /etc/os-release missing."
  exit 1
fi


MODULE_NAME="nvidia-570"
ACTION="${1:-all}"
VERSION="570.172.08"
URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${VERSION}/NVIDIA-Linux-x86_64-${VERSION}.run"
INSTALLER="NVIDIA-Linux-x86_64-${VERSION}.run"
EXTRACT_DIR="NVIDIA-Linux-x86_64-${VERSION}"
DEB_NAME="nvidia-driver-${VERSION}"
DEB_FILE="${DEB_NAME}_${VERSION}_amd64.deb"

RUBY_INSTALLED_BEFORE=0
[[ -x "$(command -v ruby)" ]] && RUBY_INSTALLED_BEFORE=1

# === Shared cleanup for Ruby + fpm ===
ruby_fpm_cleanup() {
  if [[ $RUBY_INSTALLED_BEFORE -eq 0 ]]; then
    echo "🧽 Removing temporary Ruby + fpm..."
    sudo gem uninstall -aIx fpm || true
    sudo apt remove --purge -y ruby ruby-dev
    sudo apt autoremove -y
  fi
}

# === deps ===
install_dependencies() {
  echo "📦 Installing build dependencies..."
  sudo apt update
  sudo apt install -y dkms build-essential linux-headers-$(uname -r) curl gcc make

  if [[ $RUBY_INSTALLED_BEFORE -eq 0 ]]; then
    echo "💎 Installing Ruby temporarily..."
    sudo apt install -y ruby ruby-dev
  fi

  gem list -i fpm >/dev/null || sudo gem install --no-document fpm
}

# === install ===
install_driver() {
  echo "⬇️  Downloading NVIDIA ${VERSION} driver..."
  curl -fL -O "$URL"

  # Validate download
  if ! file "$INSTALLER" | grep -q "shell script"; then
    echo "❌ The downloaded NVIDIA installer is not valid. Possible network or URL issue."
    rm -f "$INSTALLER"
    exit 1
  fi

  chmod +x "$INSTALLER"

  if [[ -d "$EXTRACT_DIR" ]]; then
    echo "🧽 Removing previous extraction at $EXTRACT_DIR"
    sudo rm -rf "$EXTRACT_DIR"
  fi

  echo "📦 Extracting installer..."
  ./"$INSTALLER" --extract-only

  cd "$EXTRACT_DIR"

  echo "🔧 Registering DKMS module..."
  sudo ./nvidia-installer --dkms --add-this-kernel \
    --silent \
    --no-install-compat32-libs \
    --no-install-libglvnd || echo "⚠️ Installer warning. Likely safe to continue."

  echo "📦 Building .deb with FPM..."
  fpm -s dir -t deb -n "$DEB_NAME" \
      -v "$VERSION" \
      --prefix=/usr \
      -C . \
      --description "NVIDIA ${VERSION} proprietary driver (repackaged for Debian)" \
      .

  echo "✅ Installing package: $DEB_FILE"
  sudo dpkg -i "$DEB_FILE"
  sudo dkms autoinstall
  sudo update-initramfs -u

  cd ..
  rm -f "$INSTALLER"
  sudo rm -rf "$EXTRACT_DIR"

  ruby_fpm_cleanup
}

# === config ===
config_driver() {
  echo "⚙️  Enabling NVIDIA memory preservation..."
  echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-power.conf
  sudo update-initramfs -u
  echo "✅ Config applied. Reboot recommended."
}

# === clean ===
clean_driver() {
  echo "🧹 Cleaning up NVIDIA ${VERSION}..."

  sudo apt remove --purge -y "$DEB_NAME" || true
  sudo dkms remove nvidia/${VERSION} --all || true
  sudo rm -f *.run *.deb
  sudo rm -rf "$EXTRACT_DIR"

  ruby_fpm_cleanup

  echo "✅ Cleanup complete."
}

# === Entry point ===
case "$ACTION" in
  deps) install_dependencies ;;
  install) install_driver ;;
  config) config_driver ;;
  clean) clean_driver ;;
  all)
    install_dependencies
    install_driver
    config_driver
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [all|deps|install|config|clean]"
    exit 1
    ;;
esac
