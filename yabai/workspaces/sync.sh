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

# Get currently focused space info (label and display)
current_space_info=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | "\(.label)|\(.display)"')
current_space="${current_space_info%|*}"
current_display="${current_space_info#*|}"

# Get the previously tracked space (if any)
prev_space=$("$STATE_CMD" get 'workspace.currentSpace' 2>/dev/null)

# If the focused space hasn't changed, exit early (avoids false triggers from space moves)
if [[ "$current_space" == "$prev_space" ]]; then
    "$YABAI_DIR/lib/refresh_bar.sh" workspace
    exit 0
fi

# Save current space for next time
"$STATE_CMD" set 'workspace.currentSpace' "$current_space"

# Function to save last space for a workspace on a specific display
save_last_space() {
    local workspace="$1"
    local space_num="$2"
    local display="$3"
    if [[ -n "$workspace" && -n "$space_num" && -n "$display" ]]; then
        # Get current lastSpace object for this workspace (or create empty)
        local current_obj
        current_obj=$("$STATE_CMD" get "workspace.lastSpace.${workspace}" 2>/dev/null)
        if [[ -z "$current_obj" || "$current_obj" == "null" ]]; then
            current_obj='{}'
        fi
        # Update with new display->space mapping
        local new_obj
        new_obj=$(echo "$current_obj" | jq --arg d "$display" --arg s "$space_num" '.[$d] = $s')
        "$STATE_CMD" set "workspace.lastSpace.${workspace}" "$new_obj"
    fi
}

# If previous space was a workspace-specific space, save it before we potentially switch workspaces
if [[ "$prev_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
    prev_workspace="${prev_space%_0[1-6]}"
    prev_space_num="${prev_space: -1}"
    # Get the display of the previous space
    prev_display=$(yabai -m query --spaces | jq -r --arg label "$prev_space" '.[] | select(.label == $label) | .display')
    if [[ -n "$prev_display" ]]; then
        save_last_space "$prev_workspace" "$prev_space_num" "$prev_display"
    fi
# If previous space was a shared space (7-10), save it for the current workspace
elif [[ "$prev_space" =~ ^(work|personal)_0([7-9])$ ]]; then
    prev_space_num="${BASH_REMATCH[2]}"
    prev_display=$(yabai -m query --spaces | jq -r --arg label "$prev_space" '.[] | select(.label == $label) | .display')
    current_workspace=$("$STATE_CMD" get 'workspace.active' 2>/dev/null)
    if [[ -n "$prev_display" && -n "$current_workspace" ]]; then
        save_last_space "$current_workspace" "$prev_space_num" "$prev_display"
    fi
elif [[ "$prev_space" =~ ^(work|personal)_10$ ]]; then
    prev_space_num="10"
    prev_display=$(yabai -m query --spaces | jq -r --arg label "$prev_space" '.[] | select(.label == $label) | .display')
    current_workspace=$("$STATE_CMD" get 'workspace.active' 2>/dev/null)
    if [[ -n "$prev_display" && -n "$current_workspace" ]]; then
        save_last_space "$current_workspace" "$prev_space_num" "$prev_display"
    fi
fi

# Check if it's a workspace-specific space (pattern: {workspace}_0[1-6])
if [[ "$current_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
    # Extract workspace name from the label
    workspace_from_space="${current_space%_0[1-6]}"
    space_num="${current_space: -1}"

    # Update stored state
    "$STATE_CMD" set 'workspace.active' "$workspace_from_space"

    # Also save this as the last space for this workspace on this display
    save_last_space "$workspace_from_space" "$space_num" "$current_display"

# Check if it's a shared space (pattern: {profile}_0[7-9] or {profile}_10)
elif [[ "$current_space" =~ ^(work|personal)_0([7-9])$ ]]; then
    # Extract profile type and space number from the space label
    space_profile="${BASH_REMATCH[1]}"
    space_num="${BASH_REMATCH[2]}"

    # Get current active workspace and its profile
    current_workspace=$("$STATE_CMD" get 'workspace.active' 2>/dev/null)
    current_profile=$("$MANAGER_CMD" profile "$current_workspace" 2>/dev/null)

    # Save this shared space as lastSpace for the current workspace on this display
    if [[ -n "$current_workspace" && "$current_profile" == "$space_profile" ]]; then
        save_last_space "$current_workspace" "$space_num" "$current_display"
    fi

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
                # Also save this space for the new workspace
                save_last_space "$new_workspace" "$space_num" "$current_display"
            fi
        fi
    fi

elif [[ "$current_space" =~ ^(work|personal)_10$ ]]; then
    # Extract profile type from the space label
    space_profile="${current_space%%_*}"
    space_num="10"

    # Get current active workspace and its profile
    current_workspace=$("$STATE_CMD" get 'workspace.active' 2>/dev/null)
    current_profile=$("$MANAGER_CMD" profile "$current_workspace" 2>/dev/null)

    # Save this shared space as lastSpace for the current workspace on this display
    if [[ -n "$current_workspace" && "$current_profile" == "$space_profile" ]]; then
        save_last_space "$current_workspace" "$space_num" "$current_display"
    fi

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
                # Also save this space for the new workspace
                save_last_space "$new_workspace" "$space_num" "$current_display"
            fi
        fi
    fi
fi

# Refresh the workspace widget
"$YABAI_DIR/lib/refresh_bar.sh" workspace
