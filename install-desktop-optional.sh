#!/bin/bash
set -e

ACTION="${1:-all}"

# Define optional modules and how to detect them
declare -A MODULES=(
  [1password]="command -v 1password"
  [chrome]="command -v google-chrome"
  [vscode]="command -v code"
  [kitty]="command -v kitty"
  [lens]="command -v lens"
  [jetbrains-toolbox]="command -v jetbrains-toolbox"
  [firefox-pwa] ="command -v firefox"
)

MODULE_DIR="./modules"

run_installer_for() {
  local name="$1"
  local script="$MODULE_DIR/install-$name.sh"

  if [[ -f "$script" ]]; then
    gum spin --title "Installing $name..." -- bash "$script" install
  else
    echo "⚠️ Missing script: $script"
  fi
}

main() {
  local list=()
  local preselect=()

  for name in "${!MODULES[@]}"; do
    list+=("$name")
    if eval "${MODULES[$name]}" &>/dev/null; then
      preselect+=("$name")
    fi
  done

  # Show checklist with installed modules preselected
  local selected=()
  IFS=$'\n' read -r -d '' -a selected < <(
    printf "%s\n" "${list[@]}" | gum choose --no-limit --selected="${preselect[*]}" \
      --header="Select packages to install" --height=15 && printf '\0'
  )

  [[ ${#selected[@]} -eq 0 ]] && echo "❌ Nothing selected. Exiting." && exit 0

  for name in "${selected[@]}"; do
    run_installer_for "$name"
  done

  echo "✅ Done."
}

[[ "$ACTION" == "all" ]] && main
