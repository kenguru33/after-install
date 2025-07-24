#!/bin/bash
set -e

# Output a status line with emoji + text
print_status() {
  local name="$1"
  local condition="$2"

  if [[ "$condition" == "ok" ]]; then
    echo "✅ $name is installed."
  elif [[ "$condition" == "warn" ]]; then
    echo "⚠️  $name is partially configured."
  else
    echo "❌ $name is missing."
  fi
}

# === Common status checks ===

status_check_binary() {
  local binary="$1"
  local label="${2:-$binary}"

  if command -v "$binary" &>/dev/null; then
    print_status "$label" "ok"
  else
    print_status "$label" "missing"
  fi
}

status_check_file() {
  local file="$1"
  local label="${2:-$file}"

  if [[ -f "$file" ]]; then
    print_status "$label" "ok"
  else
    print_status "$label" "missing"
  fi
}

status_check_dir() {
  local dir="$1"
  local label="${2:-$dir}"

  if [[ -d "$dir" ]]; then
    print_status "$label" "ok"
  else
    print_status "$label" "missing"
  fi
}

status_check_shell() {
  local user="${1:-$USER}"
  local expected_shell="${2:-zsh}"
  local current_shell
  current_shell="$(getent passwd "$user" | cut -d: -f7)"

  if [[ "$current_shell" == *"$expected_shell" ]]; then
    print_status "$user shell" "ok"
  else
    print_status "$user shell (currently: $current_shell)" "missing"
  fi
}
