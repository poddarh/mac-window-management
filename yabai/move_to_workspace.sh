#!/bin/bash

# Move window to another workspace (same space slot)
# Usage: move_to_workspace.sh <workspace_index>
# Moves window from current space slot in current workspace to same slot in target workspace

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

target_index=$1

if [[ -z "$target_index" ]]; then
    echo "Usage: move_to_workspace.sh <workspace_index>"
    exit 1
fi

# Get workspace list
workspaces=$("$SCRIPT_DIR/state.sh" get 'workspace.list')

# Get target workspace name by index (1-based)
target_workspace=$(echo "$workspaces" | jq -r --argjson idx "$((target_index - 1))" '.[$idx] // empty')

if [[ -z "$target_workspace" ]]; then
    echo "Workspace $target_index does not exist"
    exit 1
fi

# Get current space number (1-6) from current space label
current_active=$("$SCRIPT_DIR/state.sh" get 'workspace.active')
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')

space_num=""
if [[ "$current_space" =~ ^${current_active}_0([1-6])$ ]]; then
    space_num="${BASH_REMATCH[1]}"
fi

if [[ -z "$space_num" ]]; then
    echo "Current space is not a workspace-specific space (1-6)"
    exit 1
fi

# Target space label
target_label="${target_workspace}_0${space_num}"

# Create target space if needed
"$SCRIPT_DIR/create_space.sh" "0${space_num}" "$target_workspace"

# Move window to target space
yabai -m window --space "$target_label"

# Notify bar
"$SCRIPT_DIR/notify_bar.sh"
