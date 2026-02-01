#!/bin/bash

# Move window to another workspace via dialog

PATH=/opt/homebrew/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Capture window and space info BEFORE showing dialog (dialog will steal focus)
window_id=$(yabai -m query --windows --window | jq -r '.id')
current_space=$(yabai -m query --spaces | jq -r '.[] | select(."has-focus") | .label')

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
    set targetChoice to choose from list workspaceList with prompt \"Move window to:\" with title \"Move Window\" OK button name \"Move\" cancel button name \"Cancel\"
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

# Extract space number from label
space_num=""
if [[ "$current_space" =~ _0([1-6])$ ]]; then
    space_num="${BASH_REMATCH[1]}"
fi

if [[ -z "$space_num" ]]; then
    # On a shared space (7-10), move to space 01 of target workspace
    space_num="1"
fi

# Create target space if needed
target_label="${target_workspace}_0${space_num}"
"$SCRIPT_DIR/create_space.sh" "0${space_num}" "$target_workspace"

# Move the captured window (by ID) to the target space
yabai -m window "$window_id" --space "$target_label"

# Focus the target space and window
yabai -m space --focus "$target_label"
yabai -m window --focus "$window_id"

# Update active workspace
"$SCRIPT_DIR/state.sh" set 'workspace.active' "$target_workspace"

osascript -e "display notification \"Window moved to $target_workspace\" with title \"✓ Window Moved\""

# Refresh bar
"$SCRIPT_DIR/notify_bar.sh"
