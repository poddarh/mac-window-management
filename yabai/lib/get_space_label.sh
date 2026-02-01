#!/bin/bash

# Get the proper space label for a given space number
# Usage: source this file, then call get_space_label <space_num> [workspace]
# Returns the label via echo (capture with $(get_space_label ...))

# Get the directory where this script lives
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$LIB_DIR")"

get_space_label() {
    local space_num="$1"
    local workspace="${2:-}"

    # Spaces 1-6 are workspace-specific
    if [[ "$space_num" =~ ^0[1-6]$ ]]; then
        # Get workspace from argument or state
        if [[ -z "$workspace" ]]; then
            workspace=$("$YABAI_DIR/state.sh" get 'workspace.active' 2>/dev/null)
        fi
        if [[ -z "$workspace" || "$workspace" == "null" ]]; then
            workspace="default"
        fi
        echo "${workspace}_${space_num}"
    else
        # Spaces 7-10 are profile-specific (shared across workspaces of same profile)
        local profile_type
        profile_type=$("$YABAI_DIR/workspaces/manager.sh" profile 2>/dev/null || echo "personal")
        echo "${profile_type}_${space_num}"
    fi
}
