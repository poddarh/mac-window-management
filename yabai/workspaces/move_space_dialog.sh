#!/bin/bash

# Move current space to another workspace via dialog

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

# Capture space info BEFORE showing dialog
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')
current_space_index=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .index')

# Check if on a workspace-specific space (1-6)
if ! [[ "$current_space" =~ _0([1-6])$ ]]; then
    osascript -e "display notification \"Cannot move shared spaces (7-10)\" with title \"Cannot Move Space\""
    exit 1
fi

space_num="${BASH_REMATCH[1]}"

# Show workspace selection dialog
target_workspace=$("$YABAI_DIR/lib/select_workspace_dialog.sh" "Move space $space_num to:" "Move Space" "Move Space")

# Check if cancelled
if [[ -z "$target_workspace" ]]; then
    exit 0
fi

new_label="${target_workspace}_0${space_num}"

# Check if target space already exists
if yabai -m query --spaces | jq -e --arg label "$new_label" '.[] | select(.label == $label)' >/dev/null 2>&1; then
    osascript -e "display notification \"Space $space_num already exists in $target_workspace\" with title \"Cannot Move Space\""
    exit 1
fi

# Rename the space to move it to the new workspace
yabai -m space "$current_space_index" --label "$new_label"

# Focus the renamed space (ensure we follow it)
yabai -m space --focus "$new_label"

# Update active workspace
"$YABAI_DIR/state.sh" set 'workspace.active' "$target_workspace"

# Refresh bar
"$YABAI_DIR/lib/refresh_bar.sh"
