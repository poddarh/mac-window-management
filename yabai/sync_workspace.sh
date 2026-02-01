#!/bin/bash

# Sync workspace state based on currently focused space
# Called when space changes externally (via Mission Control, etc.)
# Updates stored state so shared spaces know which workspace is active

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_CMD="$SCRIPT_DIR/state.sh"

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
osascript -e 'tell application id "tracesOf.Uebersicht" to refresh widget id "nibar-workspace-jsx"' 2>/dev/null || true
