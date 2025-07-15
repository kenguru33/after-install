#!/bin/bash
set -e

trap 'gum log --level error "❌ An error occurred. Exiting."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="$SCRIPT_DIR/modules"

# === Check for required scripts ===
if [[ ! -x "$MODULES/check-sudo.sh" ]]; then
  gum style \
    --border normal \
    --margin "1" \
    --padding "1 3" \
    --foreground 1 \
    --border-foreground 9 \
    "❌ Missing or non-executable: $MODULES/check-sudo.sh"
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
  DESKTOP_STATUS=$?

  if [[ $DESKTOP_STATUS -eq 0 ]]; then
    # === Fancy logout recommendation and prompt ===
    gum style \
      --border normal \
      --margin "1" \
      --padding "1 3" \
      --foreground 208 \
      --border-foreground 166 \
      "🔄 To apply all GNOME desktop changes, you should log out and back in."

    if gum confirm "🚪 Do you want to log out now?"; then
      if command -v gnome-session-quit &>/dev/null; then
        gnome-session-quit --logout --no-prompt
      else
        gum style \
          --border normal \
          --margin "1" \
          --padding "1 3" \
          --foreground 1 \
          --border-foreground 9 \
          "⚠️  Unable to log out automatically. Please log out manually."
      fi
    fi
  else
    gum log --level error "❌ Desktop installation failed. Not prompting for logout."
    exit $DESKTOP_STATUS
  fi

else
  gum log --level info "💻 GNOME not detected. Running install-terminal.sh..."
  "$SCRIPT_DIR/install-terminal.sh" "$ACTION"
fi

# === Done ===
gum style \
  --border double \
  --margin "1" \
  --padding "1 3" \
  --foreground 10 \
  --border-foreground 2 \
  "✅ System '$ACTION' setup completed successfully!"
