#!/bin/bash

# Sync workspace state based on currently focused space
# Called when space changes externally (via Mission Control, etc.)
# Updates stored state so shared spaces know which workspace is active

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

STATE_CMD="$YABAI_DIR/state.sh"

# Get currently focused space label
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')

# Check if it's a workspace-specific space (pattern: {workspace}_0[1-6])
if [[ "$current_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
    # Extract workspace name from the label
    workspace_from_space="${current_space%_0[1-6]}"

    # Update stored state (for when we switch to shared spaces)
    "$STATE_CMD" set 'workspace.active' "$workspace_from_space"
fi

# Refresh the workspace widget
"$YABAI_DIR/lib/refresh_bar.sh" workspace
