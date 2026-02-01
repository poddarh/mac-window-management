#!/bin/bash

# Open Chrome in the correct profile based on active workspace
# If Chrome is already open on the current workspace, focus that window
# Usage: open_chrome.sh [url]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Get active workspace
workspace=$("$SCRIPT_DIR/workspaces/manager.sh" active 2>/dev/null || echo "personal")

# Get profile type for this workspace (work or personal)
profile_type=$("$SCRIPT_DIR/workspaces/manager.sh" profile "$workspace" 2>/dev/null || echo "personal")

# Map profile type to Chrome profile directory using config
profile=$(get_chrome_profile "$profile_type")

# Get all space indices for the current workspace
# Workspace-specific spaces: {workspace}_01 through {workspace}_06
# Profile-shared spaces: {profile_type}_07 through {profile_type}_10
workspace_spaces=$(yabai -m query --spaces | jq -r --arg ws "$workspace" --arg profile "$profile_type" '
    .[] | select(
        (.label | test("^" + $ws + "_0[1-6]$")) or
        (.label | test("^" + $profile + "_0[7-9]$")) or
        (.label == ($profile + "_10"))
    ) | .index
')

# Check if Chrome has any windows on these spaces
chrome_window=""
for space_idx in $workspace_spaces; do
    # Find Chrome window on this space
    window=$(yabai -m query --windows | jq -r --argjson space "$space_idx" '
        .[] | select(.app == "Google Chrome" and .space == $space) | .id
    ' | head -1)
    if [[ -n "$window" ]]; then
        chrome_window="$window"
        break
    fi
done

if [[ -n "$chrome_window" ]]; then
    # Focus existing Chrome window on this workspace
    yabai -m window --focus "$chrome_window"

    # If URL provided, open it in the focused window
    if [[ -n "$1" ]]; then
        open -a "Google Chrome" "$1"
    fi
else
    # No Chrome window on current workspace, open new one with correct profile
    if [[ -n "$1" ]]; then
        open -na "Google Chrome" --args --profile-directory="$profile" "$1"
    else
        open -na "Google Chrome" --args --profile-directory="$profile"
    fi
fi
