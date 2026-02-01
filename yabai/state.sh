#!/bin/bash

# State management for yabai window manager
# Provides centralized state storage at ~/.yabai/state.json

PATH=/opt/homebrew/bin:$PATH

STATE_DIR="$HOME/.yabai"
STATE_FILE="$STATE_DIR/state.json"

# Default state structure
DEFAULT_STATE='{
  "workspace": {
    "active": "default",
    "list": ["default"]
  },
  "skhd": {
    "mode": "default"
  }
}'

# Ensure state directory and file exist with defaults
init() {
    mkdir -p "$STATE_DIR"
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "$DEFAULT_STATE" > "$STATE_FILE"
    fi

    # Migrate from old ~/.skhd_state if it exists
    if [[ -f "$HOME/.skhd_state" ]]; then
        old_mode=$(cat "$HOME/.skhd_state")
        if [[ -n "$old_mode" ]]; then
            set "skhd.mode" "$old_mode"
        fi
        rm -f "$HOME/.skhd_state"
    fi
}

# Get a value from state.json
# Usage: state.sh get <path>
# Example: state.sh get workspace.active
get() {
    local path="$1"

    if [[ ! -f "$STATE_FILE" ]]; then
        init
    fi

    # Convert dot notation to jq path
    local jq_path=".$path"
    jq -r "$jq_path" "$STATE_FILE"
}

# Set a value in state.json
# Usage: state.sh set <path> <value>
# Example: state.sh set workspace.active "personal"
set() {
    local path="$1"
    local value="$2"

    if [[ ! -f "$STATE_FILE" ]]; then
        init
    fi

    # Convert dot notation to jq path
    local jq_path=".$path"

    # Determine if value is a JSON type (array/object/number/boolean) or string
    if echo "$value" | jq -e . >/dev/null 2>&1; then
        # Value is valid JSON, use it as-is
        jq "$jq_path = $value" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
        # Value is a string, quote it
        jq "$jq_path = \"$value\"" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
}

# Main command dispatcher
case "$1" in
    init)
        init
        ;;
    get)
        get "$2"
        ;;
    set)
        set "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {init|get|set} [args...]"
        echo "  init           - Initialize state file with defaults"
        echo "  get <path>     - Get value (e.g., workspace.active)"
        echo "  set <path> <v> - Set value (e.g., workspace.active personal)"
        exit 1
        ;;
esac
