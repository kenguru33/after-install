#!/bin/bash
set -e

REPO_DIR="$HOME/.after-install"

if [ -d "$REPO_DIR" ]; then
  echo "📦 Updating existing repo..."
  git -C "$REPO_DIR" pull
else
  echo "📥 Cloning after-install repo..."
  git clone https://github.com/kenguru33/after-install.git "$REPO_DIR"
fi

cd "$REPO_DIR"
bash install.sh all
