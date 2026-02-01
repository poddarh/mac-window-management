#!/bin/bash

# Move window to a space with workspace awareness
# Usage: move_to_space.sh <space_number>
# For spaces 1-6: moves to {active_workspace}_0N
# For spaces 7-10: moves to space_0N or space_10

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

space_num=$1

if [[ -z "$space_num" ]]; then
    echo "Usage: move_to_space.sh <space_number>"
    exit 1
fi

# Determine the label based on space number
if [[ "$space_num" =~ ^0[1-6]$ ]]; then
    # Workspace-specific space (1-6)
    workspace=$("$SCRIPT_DIR/state.sh" get 'workspace.active' 2>/dev/null || echo "default")
    if [[ -z "$workspace" || "$workspace" == "null" ]]; then
        workspace="default"
    fi
    label="${workspace}_${space_num}"
else
    # Shared space (7-10)
    label="space_${space_num}"
fi

# Ensure space exists
"$SCRIPT_DIR/create_space.sh" "$space_num"

# Move window to the space
yabai -m window --space "$label"

# Notify bar
"$SCRIPT_DIR/notify_bar.sh"
