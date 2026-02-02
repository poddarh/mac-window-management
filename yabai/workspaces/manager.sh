#!/bin/bash

# Workspace management for yabai window manager
# Manages virtual workspaces where spaces 1-6 are workspace-specific
# and spaces 7-10 are shared across all workspaces

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

STATE_CMD="$YABAI_DIR/state.sh"
REFRESH_BAR="$YABAI_DIR/lib/refresh_bar.sh"

# List all workspaces
list() {
    "$STATE_CMD" get 'workspace.list | .[]' 2>/dev/null || echo "default"
}

# Get active workspace name
# Derives from focused space when on a workspace-specific space,
# otherwise falls back to stored state
active() {
    local current_space
    current_space=$(yabai -m query --spaces 2>/dev/null | jq -r '.[] | select(."has-focus") | .label')

    # Check if it's a workspace-specific space (pattern: {workspace}_0[1-6])
    if [[ "$current_space" =~ ^([a-zA-Z][a-zA-Z0-9_]*)_0[1-6]$ ]]; then
        # Extract workspace name from the label
        echo "${current_space%_0[1-6]}"
    else
        # On a shared space or unknown - use stored state
        "$STATE_CMD" get 'workspace.active' 2>/dev/null || echo "default"
    fi
}

# Switch to a workspace
# Usage: workspaces.sh switch <name>
switch() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "Usage: workspaces.sh switch <name>"
        exit 1
    fi

    # Verify workspace exists
    local workspaces
    workspaces=$("$STATE_CMD" get 'workspace.list')
    if ! echo "$workspaces" | jq -e --arg name "$name" 'index($name) != null' >/dev/null 2>&1; then
        echo "Workspace '$name' does not exist"
        exit 1
    fi

    # Get current active workspace and its profile
    local current_active
    current_active=$(active)
    local current_profile
    current_profile=$(profile "$current_active")
    local target_profile
    target_profile=$(profile "$name")

    # Get currently focused space info
    local current_space_info
    current_space_info=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | "\(.label)|\(.display)"')
    local current_space="${current_space_info%|*}"
    local current_display="${current_space_info#*|}"

    # Check if we're on a profile-shared space (7-10)
    local on_shared_space=false
    if [[ "$current_space" =~ ^(work|personal)_0[7-9]$ ]] || [[ "$current_space" =~ ^(work|personal)_10$ ]]; then
        on_shared_space=true
    fi

    # Save current space for current workspace on current display (if on a workspace-specific space)
    if [[ "$current_space" =~ ^${current_active}_0[1-6]$ ]]; then
        local current_space_num="${current_space: -1}"
        # Get current lastSpace object for this workspace
        local current_obj
        current_obj=$("$STATE_CMD" get "workspace.lastSpace.${current_active}" 2>/dev/null)
        if [[ -z "$current_obj" || "$current_obj" == "null" ]]; then
            current_obj='{}'
        fi
        local new_obj
        new_obj=$(echo "$current_obj" | jq --arg d "$current_display" --arg s "$current_space_num" '.[$d] = $s')
        "$STATE_CMD" set "workspace.lastSpace.${current_active}" "$new_obj"
    fi

    # Update active workspace
    "$STATE_CMD" set 'workspace.active' "$name"

    # If on a shared space and staying on same profile type, just update state
    if [[ "$on_shared_space" == true && "$current_profile" == "$target_profile" ]]; then
        "$REFRESH_BAR"
        return
    fi

    # Get all displays
    local displays
    displays=$(yabai -m query --displays | jq -r '.[].index')

    # Get lastSpace object for target workspace
    local last_space_obj
    last_space_obj=$("$STATE_CMD" get "workspace.lastSpace.${name}" 2>/dev/null)
    if [[ -z "$last_space_obj" || "$last_space_obj" == "null" ]]; then
        last_space_obj='{}'
    fi

    # Check if target workspace has any spaces
    local target_spaces
    target_spaces=$(yabai -m query --spaces | jq -r --arg prefix "${name}_" '[.[] | select(.label | startswith($prefix) and test("_0[1-6]$"))] | length')

    if [[ "$target_spaces" -eq 0 ]]; then
        # No spaces exist for this workspace - create space 01
        "$YABAI_DIR/spaces/create.sh" "01" "$name"
    fi

    # Focus appropriate space on each display (never move spaces between displays)
    for display in $displays; do
        # Get the last space for this workspace on this display
        local target_space_num
        target_space_num=$(echo "$last_space_obj" | jq -r --arg d "$display" '.[$d] // empty')
        if [[ -z "$target_space_num" || "$target_space_num" == "null" ]]; then
            target_space_num="1"
        fi

        local target_label
        # Check if it's a shared space (7-10) - use profile prefix instead of workspace
        if [[ "$target_space_num" =~ ^(7|8|9|10)$ ]]; then
            if [[ "$target_space_num" == "10" ]]; then
                target_label="${target_profile}_10"
            else
                target_label="${target_profile}_0${target_space_num}"
            fi
        else
            target_label="${name}_0${target_space_num}"
        fi

        # Check if target space exists on this display
        local space_on_display
        space_on_display=$(yabai -m query --spaces | jq -r --arg label "$target_label" --argjson display "$display" \
            '.[] | select(.label == $label and .display == $display) | .label')

        if [[ -n "$space_on_display" ]]; then
            # Space exists on this display, focus it
            yabai -m space --focus "$target_label" 2>/dev/null || true
        else
            # Find any workspace-specific space for this workspace on this display
            local any_space_on_display
            any_space_on_display=$(yabai -m query --spaces | jq -r --arg prefix "${name}_0" --argjson display "$display" \
                '[.[] | select(.label | startswith($prefix) and test("_0[1-6]$")) | select(.display == $display)] | sort_by(.label) | .[0].label // empty')

            if [[ -n "$any_space_on_display" ]]; then
                yabai -m space --focus "$any_space_on_display" 2>/dev/null || true
            else
                # Try to find a shared space for this profile on this display
                local shared_space_on_display
                shared_space_on_display=$(yabai -m query --spaces | jq -r --arg profile "$target_profile" --argjson display "$display" \
                    '[.[] | select(.label | startswith($profile + "_")) | select(.label | test("_0[7-9]$|_10$")) | select(.display == $display)] | sort_by(.label) | .[0].label // empty')
                if [[ -n "$shared_space_on_display" ]]; then
                    yabai -m space --focus "$shared_space_on_display" 2>/dev/null || true
                fi
            fi
            # If no space for this workspace/profile on this display, leave it as-is
        fi
    done

    # Notify bar to refresh
    "$REFRESH_BAR"
}

# Create a new workspace
# Usage: workspaces.sh create <name> [profile]
# profile: "work" or "personal" (default: personal)
create() {
    local name="$1"
    local profile="${2:-personal}"

    if [[ -z "$name" ]]; then
        echo "Usage: workspaces.sh create <name> [work|personal]"
        exit 1
    fi

    # Validate name (alphanumeric and underscore only)
    if ! [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid workspace name. Use alphanumeric characters and underscores, starting with a letter."
        exit 1
    fi

    # Validate profile
    if [[ "$profile" != "work" && "$profile" != "personal" ]]; then
        echo "Invalid profile type. Use 'work' or 'personal'."
        exit 1
    fi

    # Check if workspace already exists
    local workspaces
    workspaces=$("$STATE_CMD" get 'workspace.list')
    if echo "$workspaces" | jq -e --arg name "$name" 'index($name) != null' >/dev/null 2>&1; then
        echo "Workspace '$name' already exists"
        exit 1
    fi

    # Add to workspace list
    local new_list
    new_list=$(echo "$workspaces" | jq --arg name "$name" '. + [$name]')
    "$STATE_CMD" set 'workspace.list' "$new_list"

    # Store the profile type for this workspace
    "$STATE_CMD" set "workspace.profiles.${name}" "$profile"

    # Create the 6 spaces for this workspace
    for i in 01 02 03 04 05 06; do
        "$YABAI_DIR/spaces/create.sh" "$i" "$name"
    done

    # Switch to the new workspace
    "$STATE_CMD" set 'workspace.active' "$name"

    # Focus first space
    yabai -m space --focus "${name}_01" 2>/dev/null || true

    # Notify bar to refresh
    "$REFRESH_BAR"

    echo "Created workspace '$name' with profile '$profile'"
}

# Delete a workspace
# Usage: workspaces.sh delete <name>
delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "Usage: workspaces.sh delete <name>"
        exit 1
    fi

    # Verify workspace exists
    local workspaces
    workspaces=$("$STATE_CMD" get 'workspace.list')
    if ! echo "$workspaces" | jq -e --arg name "$name" 'index($name) != null' >/dev/null 2>&1; then
        echo "Workspace '$name' does not exist"
        exit 1
    fi

    # Get workspace-specific space indices (only spaces 1-6, pattern: {name}_0[1-6])
    local workspace_space_indices
    workspace_space_indices=$(yabai -m query --spaces | jq -r --arg name "$name" '
        [.[] | select(.label | test("^" + $name + "_0[1-6]$")) | .index] | join(",")
    ')

    # Count unique, non-sticky windows on workspace-specific spaces only
    local window_count=0
    if [[ -n "$workspace_space_indices" ]]; then
        window_count=$(yabai -m query --windows | jq -r --arg spaces "$workspace_space_indices" '
            ($spaces | split(",") | map(select(. != "") | tonumber)) as $space_list |
            [.[] | select(
                (.["is-sticky"] != true) and
                (.space as $s | $space_list | index($s) != null)
            ) | .id] | unique | length
        ')
    fi

    if [[ "$window_count" -gt 0 ]]; then
        echo "Cannot delete workspace '$name': it has $window_count window(s). Move or close them first."
        # Show notification since nibar can't display error messages
        osascript -e "display notification \"Workspace '$name' has $window_count window(s). Move or close them first.\" with title \"Cannot Delete Workspace\""
        exit 1
    fi

    # Get spaces for this workspace
    local spaces_to_delete
    spaces_to_delete=$(yabai -m query --spaces | jq -r --arg prefix "${name}_" '.[] | select(.label | startswith($prefix)) | .index' | sort -rn)

    # Switch to another workspace first if this is the active one
    local current_active
    current_active=$(active)
    if [[ "$current_active" == "$name" ]]; then
        # Find another workspace to switch to
        local other_workspace
        other_workspace=$(echo "$workspaces" | jq -r --arg name "$name" '.[] | select(. != $name)' | head -1)
        if [[ -n "$other_workspace" ]]; then
            switch "$other_workspace"
        else
            # Create default workspace if this was the last one
            local new_list='["default"]'
            "$STATE_CMD" set 'workspace.list' "$new_list"
            "$STATE_CMD" set 'workspace.active' "default"
            # Create default workspace spaces after deletion
        fi
    fi

    # Delete all spaces for this workspace (in reverse order to avoid index shifts)
    for space_index in $spaces_to_delete; do
        yabai -m space "$space_index" --destroy 2>/dev/null || true
    done

    # Remove from workspace list
    local new_list
    new_list=$(echo "$workspaces" | jq --arg name "$name" 'map(select(. != $name))')

    # If list is empty, add default workspace
    if [[ $(echo "$new_list" | jq 'length') -eq 0 ]]; then
        new_list='["default"]'
        "$STATE_CMD" set 'workspace.active' "default"
        # Create default workspace spaces
        for i in 01 02 03 04 05 06; do
            "$YABAI_DIR/spaces/create.sh" "$i" "default"
        done
    fi

    "$STATE_CMD" set 'workspace.list' "$new_list"

    # Notify bar to refresh
    "$REFRESH_BAR"

    echo "Deleted workspace '$name'"
}

# Rename a workspace
# Usage: workspaces.sh rename <old_name> <new_name>
rename() {
    local old_name="$1"
    local new_name="$2"

    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo "Usage: workspaces.sh rename <old_name> <new_name>"
        exit 1
    fi

    # Validate new name
    if ! [[ "$new_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid workspace name. Use alphanumeric characters and underscores, starting with a letter."
        exit 1
    fi

    # Verify old workspace exists
    local workspaces
    workspaces=$("$STATE_CMD" get 'workspace.list')
    if ! echo "$workspaces" | jq -e --arg name "$old_name" 'index($name) != null' >/dev/null 2>&1; then
        echo "Workspace '$old_name' does not exist"
        exit 1
    fi

    # Check new name doesn't exist
    if echo "$workspaces" | jq -e --arg name "$new_name" 'index($name) != null' >/dev/null 2>&1; then
        echo "Workspace '$new_name' already exists"
        exit 1
    fi

    # Rename all spaces for this workspace
    for i in 01 02 03 04 05 06; do
        local old_label="${old_name}_$i"
        local new_label="${new_name}_$i"
        if yabai -m query --spaces | jq -e --arg label "$old_label" '.[] | select(.label == $label)' >/dev/null 2>&1; then
            yabai -m space "$old_label" --label "$new_label"
        fi
    done

    # Update workspace list
    local new_list
    new_list=$(echo "$workspaces" | jq --arg old "$old_name" --arg new "$new_name" 'map(if . == $old then $new else . end)')
    "$STATE_CMD" set 'workspace.list' "$new_list"

    # Update active if needed
    local current_active
    current_active=$(active)
    if [[ "$current_active" == "$old_name" ]]; then
        "$STATE_CMD" set 'workspace.active' "$new_name"
    fi

    # Notify bar to refresh
    "$REFRESH_BAR"

    echo "Renamed workspace '$old_name' to '$new_name'"
}

# Cycle to next workspace
cycle() {
    local workspaces
    workspaces=$("$STATE_CMD" get 'workspace.list')
    local current_active
    current_active=$(active)

    local next_workspace
    next_workspace=$(echo "$workspaces" | jq -r --arg current "$current_active" '
        . as $list |
        (index($current) // 0) as $idx |
        .[($idx + 1) % length]
    ')

    if [[ -n "$next_workspace" && "$next_workspace" != "null" ]]; then
        switch "$next_workspace"
    fi
}

# Get profile type for a workspace (or current workspace if none specified)
# Usage: workspaces.sh profile [name]
# Returns: "work" or "personal"
profile() {
    local name="${1:-$(active)}"
    local profile
    profile=$("$STATE_CMD" get "workspace.profiles.${name}" 2>/dev/null)

    if [[ -z "$profile" || "$profile" == "null" ]]; then
        # Default to personal for unknown workspaces
        echo "personal"
    else
        echo "$profile"
    fi
}

# Query workspace data as JSON (for nibar widget)
# Usage: workspaces.sh query
query() {
    local active_workspace
    active_workspace=$(active)

    local workspace_list
    workspace_list=$("$STATE_CMD" get 'workspace.list' 2>/dev/null || echo '["default"]')

    local workspace_profiles
    workspace_profiles=$("$STATE_CMD" get 'workspace.profiles' 2>/dev/null || echo '{}')

    cat <<EOF
{
  "activeWorkspace": "$active_workspace",
  "workspaces": $workspace_list,
  "workspaceProfiles": $workspace_profiles
}
EOF
}

# Main command dispatcher
case "$1" in
    list)
        list
        ;;
    active)
        active
        ;;
    profile)
        profile "$2"
        ;;
    query)
        query
        ;;
    switch)
        switch "$2"
        ;;
    create)
        create "$2" "$3"
        ;;
    delete)
        delete "$2"
        ;;
    rename)
        rename "$2" "$3"
        ;;
    cycle)
        cycle
        ;;
    *)
        echo "Usage: $0 {list|active|profile|query|switch|create|delete|rename|cycle} [args...]"
        echo "  list              - List all workspaces"
        echo "  active            - Get active workspace name"
        echo "  profile [name]    - Get profile type (work/personal) for workspace"
        echo "  query             - Get workspace data as JSON (for widgets)"
        echo "  switch <name>     - Switch to a workspace"
        echo "  create <name> [profile] - Create a new workspace (profile: work|personal)"
        echo "  delete <name>     - Delete a workspace"
        echo "  rename <old> <new> - Rename a workspace"
        echo "  cycle             - Cycle to next workspace"
        exit 1
        ;;
esac
