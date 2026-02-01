#!/bin/bash

# Open Chrome in the correct profile based on active workspace
# If Chrome is already open on the current workspace, focus that window
# Usage: open_chrome.sh [url]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Get active workspace from state
workspace=$("$SCRIPT_DIR/workspaces/manager.sh" active 2>/dev/null || echo "personal")

# Get profile type for this workspace (work or personal)
profile_type=$("$SCRIPT_DIR/workspaces/manager.sh" profile "$workspace" 2>/dev/null || echo "personal")

# Map profile type to Chrome profile directory using config
profile=$(get_chrome_profile "$profile_type")

# Remember current space index AND label before doing anything
current_space_index=$(yabai -m query --spaces --space | jq -r '.index')
current_space_label=$(yabai -m query --spaces --space | jq -r '.label')

# Build list of space labels that belong to current workspace
# Workspace-specific: {workspace}_01 through {workspace}_06
# Profile-shared: {profile_type}_07 through {profile_type}_10
workspace_space_labels=$(yabai -m query --spaces | jq -r --arg ws "$workspace" --arg profile "$profile_type" '
    [.[] | select(
        (.label | test("^" + $ws + "_0[1-6]$")) or
        (.label | test("^" + $profile + "_0[7-9]$")) or
        (.label == ($profile + "_10"))
    ) | .label] | join(" ")
')

# Get all windows data once for efficiency
all_windows=$(yabai -m query --windows)
all_spaces=$(yabai -m query --spaces)

# Find Chrome window on any of the workspace's spaces (check by label, not index)
# Only match real browser windows (AXWindow role), not tooltips or helpers
chrome_window=""
for space_label in $workspace_space_labels; do
    # Get the space index for this label
    space_idx=$(echo "$all_spaces" | jq -r --arg label "$space_label" '.[] | select(.label == $label) | .index')
    if [[ -n "$space_idx" ]]; then
        # Find Chrome window on this space - must be a real window (role=AXWindow)
        window=$(echo "$all_windows" | jq -r --argjson space "$space_idx" '
            .[] | select(.app == "Google Chrome" and .space == $space and .role == "AXWindow") | .id
        ' | head -1)
        if [[ -n "$window" ]]; then
            chrome_window="$window"
            break
        fi
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
    # No Chrome window on current workspace - create a new one

    # Get list of existing Chrome window IDs before creating new window
    existing_windows=$(echo "$all_windows" | jq -r '[.[] | select(.app == "Google Chrome") | .id] | sort | join(",")')

    # Check if Chrome is running at all
    chrome_running=$(pgrep -x "Google Chrome" || true)

    if [[ -z "$chrome_running" ]]; then
        # Chrome not running - start it with the correct profile in background
        open -gja "Google Chrome" --args --profile-directory="$profile"
        sleep 0.5
    fi

    # Create a new window via AppleScript WITHOUT activating Chrome
    # This prevents Chrome from stealing focus and switching spaces
    if [[ -n "$1" ]]; then
        osascript <<EOF
tell application "Google Chrome"
    make new window
    set URL of active tab of front window to "$1"
end tell
EOF
    else
        osascript -e 'tell application "Google Chrome" to make new window'
    fi

    # Wait for new window to appear
    new_window=""
    for i in {1..30}; do
        sleep 0.1
        new_window=$(yabai -m query --windows | jq -r --arg existing "$existing_windows" '
            [.[] | select(.app == "Google Chrome") | .id] as $all |
            ($existing | split(",") | map(select(. != "") | tonumber)) as $old |
            ($all - $old)[0] // empty
        ')
        if [[ -n "$new_window" ]]; then
            break
        fi
    done

    # Move the new window to the original space and focus it
    if [[ -n "$new_window" ]]; then
        # Move to the space we were on when script started
        yabai -m window "$new_window" --space "$current_space_index"
        sleep 0.1

        # Ensure we're on the correct space (in case Chrome switched us)
        yabai -m space --focus "$current_space_index"
        sleep 0.05

        # Focus the new Chrome window
        yabai -m window --focus "$new_window"
    fi
fi
