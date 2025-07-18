main() {
  local list=()
  local preselect=()

  for name in "${!MODULES[@]}"; do
    list+=("$name")
    if eval "${MODULES[$name]}" &>/dev/null; then
      preselect+=("$name")
    fi
  done

  # Build correct multiple --selected arguments
  local SELECTED_ARGS=()
  for item in "${preselect[@]}"; do
    SELECTED_ARGS+=(--selected "$item")
  done

  # Show checklist with installed modules preselected
  local selected=()
  IFS=$'\n' read -r -d '' -a selected < <(
    printf "%s\n" "${list[@]}" | gum choose --no-limit "${SELECTED_ARGS[@]}" \
      --header="Select optional terminal packages to install" --height=15 && printf '\0'
  )

  [[ ${#selected[@]} -eq 0 ]] && echo "❌ Nothing selected. Skipping." && exit 0

  for name in "${selected[@]}"; do
    run_installer_for "$name"
  done
}
