#!/bin/bash
set -e

trap 'gum log --level error "❌ An error occurred. Exiting."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Load modules ===
MODULES="$SCRIPT_DIR/modules"

# === Check for required scripts ===
if [[ ! -x "$MODULES/check-sudo.sh" ]]; then
  gum log --level error "Missing or non-executable: $MODULES/check-sudo.sh"
  exit 1
fi

# === Run sudo check ===
"$MODULES/check-sudo.sh"

# === Determine action (default: all) ===
ACTION="${1:-all}"

# === Check for GNOME Desktop ===
if command -v gnome-shell &>/dev/null; then
  gum log --level info "🖥️ GNOME desktop detected. Running install-desktop.sh..."
  "$SCRIPT_DIR/install-desktop.sh" "$ACTION"

  # === Recommend logout to apply changes ===
  gum log --level warn "🔄 You may need to log out or restart your session to apply all desktop changes."
else
  gum log --level info "💻 GNOME not detected. Running install-terminal.sh..."
  "$SCRIPT_DIR/install-terminal.sh" "$ACTION"
fi

gum log --level success "✅ System '$ACTION' setup completed successfully!"
