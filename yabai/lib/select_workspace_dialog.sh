#!/bin/bash

# Show a workspace selection dialog
# Usage: select_workspace_dialog.sh <prompt> <title> <ok_button>
# Returns: selected workspace name (empty if cancelled)

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$LIB_DIR")"

prompt="${1:-Select workspace:}"
title="${2:-Workspace}"
ok_button="${3:-OK}"

# Get list of workspaces (excluding current)
active_workspace=$("$YABAI_DIR/workspaces/manager.sh" active)
workspaces=$("$YABAI_DIR/workspaces/manager.sh" list | grep -v "^${active_workspace}$" | tr '\n' ', ' | sed 's/,$//')

# Check if there are other workspaces
if [[ -z "$workspaces" ]]; then
    osascript -e "display notification \"No other workspaces available\" with title \"Cannot Move\""
    exit 1
fi

# Get workspace list as AppleScript list format
workspace_list=$(echo "$workspaces" | sed 's/,/", "/g')
workspace_list="\"$workspace_list\""

# Show workspace list
target_workspace=$(osascript -e "
tell application \"System Events\"
    activate
    set workspaceList to {$workspace_list}
    set targetChoice to choose from list workspaceList with prompt \"$prompt\" with title \"$title\" OK button name \"$ok_button\" cancel button name \"Cancel\"
    if targetChoice is false then
        return \"\"
    end if
    return (item 1 of targetChoice)
end tell
" 2>/dev/null)

echo "$target_workspace"
