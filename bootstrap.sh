#!/bin/bash
set -e
trap 'echo "❌ An error occurred. Exiting." >&2' ERR

SCRIPT_NAME="bootstrap.sh"
REPO_URL="https://github.com/kenguru33/after-install.git"
REPO_DIR="$HOME/.after-install"
REAL_USER="$(logname 2>/dev/null || echo "$USER")"
ACTION="all"
VERBOSE=0
GUM_VERSION="0.14.3"
BRANCH="main" # Default branch

# === Parse arguments ===
for arg in "$@"; do
  case "$arg" in
  -v | --verbose)
    VERBOSE=1
    ;;
  branch=*)
    BRANCH="${arg#branch=}"
    ;;
  *)
    echo "❌ Unknown argument: $arg"
    echo "Usage: $SCRIPT_NAME [--verbose] [branch=branchname]"
    exit 1
    ;;
  esac
done

# === Verbose helper ===
run() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

if [[ "$VERBOSE" -eq 1 ]]; then
  echo "🔍 Verbose mode enabled"
  echo "🌿 Using branch: $BRANCH"
fi

# === Detect OS ===
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="$ID"
else
  echo "❌ Could not detect OS."
  exit 1
fi

# === Prevent root execution ===
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Do not run as root. Use a normal user."
  exit 1
fi

# === Validate sudo access ===
if ! sudo -v >/dev/null 2>&1; then
  echo "🚫 User '$REAL_USER' does not have sudo privileges or authentication failed."
  echo ""
  echo "🛠️  To give this user sudo access:"
  echo "   1. Switch to root:         su -"
  echo "   2. Run this command:       usermod -aG sudo $REAL_USER"
  echo "   3. Log out and log in again (or reboot)"
  exit 1
fi

# === INSTALL: clone or update repo ===
install_repo() {
  echo "📥 Cloning or updating after-install repo (branch: $BRANCH)..."

  if [[ -d "$REPO_DIR/.git" ]]; then
    run git -C "$REPO_DIR" fetch origin
    run git -C "$REPO_DIR" checkout "$BRANCH"
    run git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
  else
    run git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
}

# === RUN: launch installer ===
run_installer() {
  cd "$REPO_DIR"

  if [[ ! -f "setup.sh" ]]; then
    echo "❌ setup.sh not found in $REPO_DIR"
    ls -la "$REPO_DIR"
    exit 1
  fi

  bash setup.sh
}
install_repo
run_installer
