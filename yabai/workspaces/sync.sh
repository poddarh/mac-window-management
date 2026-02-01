#!/bin/bash

# Sync workspace state based on currently focused space
# Called when space changes externally (via Mission Control, etc.)
# Updates stored state so shared spaces know which workspace is active

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

STATE_CMD="$YABAI_DIR/state.sh"
MANAGER_CMD="$SCRIPT_DIR/manager.sh"

# Small delay to ensure space change is complete
sleep 0.1

# Get currently focused space label
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')

# Get the previously tracked space (if any)
prev_space=$("$STATE_CMD" get 'workspace.currentSpace' 2>/dev/null)

# Save current space for next time
"$STATE_CMD" set 'workspace.currentSpace' "$current_space"

# Function to save last space for a workspace
save_last_space() {
    local workspace="$1"
    local space_num="$2"
    if [[ -n "$workspace" && -n "$space_num" ]]; then
        "$STATE_CMD" set "workspace.lastSpace.${workspace}" "$space_num"
    fi
}

# If previous space was a workspace-specific space, save it before we potentially switch workspaces
if [[ "$prev_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
    prev_workspace="${prev_space%_0[1-6]}"
    prev_space_num="${prev_space: -1}"
    save_last_space "$prev_workspace" "$prev_space_num"
fi

# Check if it's a workspace-specific space (pattern: {workspace}_0[1-6])
if [[ "$current_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
    # Extract workspace name from the label
    workspace_from_space="${current_space%_0[1-6]}"
    space_num="${current_space: -1}"

    # Update stored state
    "$STATE_CMD" set 'workspace.active' "$workspace_from_space"

    # Also save this as the last space for this workspace
    save_last_space "$workspace_from_space" "$space_num"

# Check if it's a shared space (pattern: {profile}_0[7-9] or {profile}_10)
elif [[ "$current_space" =~ ^(work|personal)_0[7-9]$ ]] || [[ "$current_space" =~ ^(work|personal)_10$ ]]; then
    # Extract profile type from the space label
    space_profile="${current_space%%_*}"

    # Get current active workspace and its profile
    current_workspace=$("$STATE_CMD" get 'workspace.active' 2>/dev/null)
    current_profile=$("$MANAGER_CMD" profile "$current_workspace" 2>/dev/null)

    # If current workspace doesn't match the space's profile, find one that does
    if [[ "$current_profile" != "$space_profile" ]]; then
        # Get workspace list and find first one with matching profile
        workspace_list=$("$STATE_CMD" get 'workspace.list' 2>/dev/null)

        if [[ -n "$workspace_list" && "$workspace_list" != "null" ]]; then
            # Find a workspace with matching profile
            new_workspace=$(echo "$workspace_list" | jq -r '.[]' | while read ws; do
                ws_profile=$("$MANAGER_CMD" profile "$ws" 2>/dev/null)
                if [[ "$ws_profile" == "$space_profile" ]]; then
                    echo "$ws"
                    break
                fi
            done)

            if [[ -n "$new_workspace" ]]; then
                "$STATE_CMD" set 'workspace.active' "$new_workspace"
            fi
        fi
    fi
fi

# Refresh the workspace widget
"$YABAI_DIR/lib/refresh_bar.sh" workspace
