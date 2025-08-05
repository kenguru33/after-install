#!/bin/bash
set -e
trap 'echo "❌ Script failed at $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-"$SCRIPT_DIR/modules/debian"}"

echo "🚀 Running all scripts in: $TARGET_DIR"

# Ensure target is a directory
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Directory not found: $TARGET_DIR"
  exit 1
fi

# Find and run all executable scripts in the folder
find "$TARGET_DIR" -maxdepth 1 -type f -name "*.sh" -executable | sort | while read -r script; do
  echo "▶️  Running: $(basename "$script")"
  "$script" all
  echo "✅ Finished: $(basename "$script")"
done

echo "🎉 All scripts completed."
