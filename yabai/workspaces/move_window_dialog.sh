#!/bin/bash

# Move window to another workspace via dialog

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

# Capture window and space info BEFORE showing dialog (dialog will steal focus)
window_id=$(yabai -m query --windows --window | jq -r '.id')
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')

# Show workspace selection dialog
target_workspace=$("$YABAI_DIR/lib/select_workspace_dialog.sh" "Move window to:" "Move Window" "Move")

# Check if cancelled
if [[ -z "$target_workspace" ]]; then
    exit 0
fi

# Extract space number from label
space_num=""
if [[ "$current_space" =~ _0([1-6])$ ]]; then
    space_num="${BASH_REMATCH[1]}"
fi

if [[ -z "$space_num" ]]; then
    # On a shared space (7-10), move to space 01 of target workspace
    space_num="1"
fi

# Create target space if needed
target_label="${target_workspace}_0${space_num}"
"$YABAI_DIR/spaces/create.sh" "0${space_num}" "$target_workspace"

# Move the captured window (by ID) to the target space
yabai -m window "$window_id" --space "$target_label"

# Focus the target space and window
yabai -m space --focus "$target_label"
yabai -m window --focus "$window_id"

# Update active workspace
"$YABAI_DIR/state.sh" set 'workspace.active' "$target_workspace"

osascript -e "display notification \"Window moved to $target_workspace\" with title \"✓ Window Moved\""

# Refresh bar
"$YABAI_DIR/lib/refresh_bar.sh"
