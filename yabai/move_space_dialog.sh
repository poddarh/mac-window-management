#!/bin/bash

# Move current space to another workspace via dialog

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Capture space info BEFORE showing dialog
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')
current_space_index=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .index')

# Check if on a workspace-specific space (1-6)
if ! [[ "$current_space" =~ _0([1-6])$ ]]; then
    osascript -e "display notification \"Cannot move shared spaces (7-10)\" with title \"Cannot Move Space\""
    exit 1
fi

space_num="${BASH_REMATCH[1]}"

# Get list of workspaces (excluding current)
active_workspace=$("$SCRIPT_DIR/workspaces.sh" active)
workspaces=$("$SCRIPT_DIR/workspaces.sh" list | grep -v "^${active_workspace}$" | tr '\n' ', ' | sed 's/,$//')

# Check if there are other workspaces
if [[ -z "$workspaces" ]]; then
    osascript -e "display notification \"No other workspaces available\" with title \"Cannot Move\""
    exit 0
fi

# Get workspace list as AppleScript list format
workspace_list=$(echo "$workspaces" | sed 's/,/", "/g')
workspace_list="\"$workspace_list\""

# Show workspace list
target_workspace=$(osascript -e "
tell application \"System Events\"
    activate
    set workspaceList to {$workspace_list}
    set targetChoice to choose from list workspaceList with prompt \"Move space $space_num to:\" with title \"Move Space\" OK button name \"Move Space\" cancel button name \"Cancel\"
    if targetChoice is false then
        return \"\"
    end if
    return (item 1 of targetChoice)
end tell
" 2>/dev/null)

# Check if cancelled
if [[ -z "$target_workspace" ]]; then
    exit 0
fi

new_label="${target_workspace}_0${space_num}"

# Check if target space already exists
if yabai -m query --spaces | jq -e --arg label "$new_label" '.[] | select(.label == $label)' >/dev/null 2>&1; then
    osascript -e "display notification \"Space $space_num already exists in $target_workspace\" with title \"Cannot Move Space\""
    exit 1
fi

# Rename the space to move it to the new workspace
yabai -m space "$current_space_index" --label "$new_label"

# Focus the renamed space (ensure we follow it)
yabai -m space --focus "$new_label"

# Update active workspace
"$SCRIPT_DIR/state.sh" set 'workspace.active' "$target_workspace"

osascript -e "display notification \"Space moved to $target_workspace\" with title \"✓ Space Moved\""

# Refresh bar
"$SCRIPT_DIR/notify_bar.sh"
