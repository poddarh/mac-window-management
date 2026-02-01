#!/bin/bash

# Focus a space with workspace awareness
# Usage: focus_space.sh <space_number>
# For spaces 1-6: focuses {active_workspace}_0N
# For spaces 7-10: focuses space_0N or space_10

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

space_num=$1

if [[ -z "$space_num" ]]; then
    echo "Usage: focus_space.sh <space_number>"
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

# Focus the space
yabai -m space --focus "$label"

# Notify bar
"$SCRIPT_DIR/notify_bar.sh"
