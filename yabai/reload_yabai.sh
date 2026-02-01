#!/bin/bash

set -e

STATE_FILE="/tmp/yabai_state.json"

save_state() {
    echo "Saving yabai state..."

    # Get all spaces with their labels and display info
    spaces=$(yabai -m query --spaces | jq '[.[] | {index: .index, label: .label, display: .display, visible: ."is-visible"}]')

    # Get all windows with their space labels (not indices, since those can change)
    # We map each window to the label of its space
    windows=$(yabai -m query --windows | jq --argjson spaces "$spaces" '
        [.[] | . as $win | {
            id: .id,
            app: .app,
            title: .title,
            space_label: ($spaces | map(select(.index == $win.space))[0].label // ""),
            space_index: .space,
            display: .display
        }]
    ')

    # Save to temp file
    jq -n --argjson spaces "$spaces" --argjson windows "$windows" '{
        spaces: $spaces,
        windows: $windows,
        timestamp: now
    }' > "$STATE_FILE"

    echo "State saved to $STATE_FILE"
    echo "  - $(echo "$spaces" | jq 'length') spaces"
    echo "  - $(echo "$windows" | jq 'length') windows"
}

reload_yabai() {
    echo "Reloading yabai..."
    yabai --restart-service

    # Wait for yabai to be ready
    echo "Waiting for yabai to restart..."
    sleep 2

    # Check if yabai is responding
    for i in {1..10}; do
        if yabai -m query --spaces &>/dev/null; then
            echo "Yabai is ready"
            return 0
        fi
        sleep 1
    done

    echo "Warning: Yabai may not be fully ready"
}

restore_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Error: No saved state found at $STATE_FILE"
        exit 1
    fi

    echo "Restoring yabai state..."

    # Read saved state
    saved_spaces=$(jq '.spaces' "$STATE_FILE")
    saved_windows=$(jq '.windows' "$STATE_FILE")

    # Get current spaces
    current_spaces=$(yabai -m query --spaces)

    # First, restore space labels
    # Match spaces by display and position (index within display)
    echo "Restoring space labels..."

    # Group saved spaces by display
    for display in $(echo "$saved_spaces" | jq -r '[.[].display] | unique | .[]'); do
        # Get saved spaces for this display (sorted by original index)
        saved_on_display=$(echo "$saved_spaces" | jq --argjson d "$display" '[.[] | select(.display == $d)] | sort_by(.index)')

        # Get current spaces for this display (sorted by index)
        current_on_display=$(echo "$current_spaces" | jq --argjson d "$display" '[.[] | select(.display == $d)] | sort_by(.index)')

        # Match by position within display and restore labels
        saved_count=$(echo "$saved_on_display" | jq 'length')
        current_count=$(echo "$current_on_display" | jq 'length')

        # Use minimum of saved and current count
        count=$((saved_count < current_count ? saved_count : current_count))

        for ((i=0; i<count; i++)); do
            saved_label=$(echo "$saved_on_display" | jq -r ".[$i].label")
            current_index=$(echo "$current_on_display" | jq -r ".[$i].index")

            if [[ -n "$saved_label" && "$saved_label" != "null" && "$saved_label" != "" ]]; then
                echo "  Labeling space $current_index as '$saved_label'"
                yabai -m space "$current_index" --label "$saved_label" 2>/dev/null || true
            fi
        done
    done

    # Refresh current spaces after labeling
    current_spaces=$(yabai -m query --spaces)

    # Now restore window positions
    echo "Restoring window positions..."

    # For each saved window that had a labeled space, move it back
    echo "$saved_windows" | jq -c '.[]' | while read -r window; do
        win_id=$(echo "$window" | jq -r '.id')
        win_app=$(echo "$window" | jq -r '.app')
        saved_label=$(echo "$window" | jq -r '.space_label')

        # Skip windows without a labeled space
        if [[ -z "$saved_label" || "$saved_label" == "null" || "$saved_label" == "" ]]; then
            continue
        fi

        # Check if window still exists
        if ! yabai -m query --windows --window "$win_id" &>/dev/null; then
            echo "  Window $win_id ($win_app) no longer exists, skipping"
            continue
        fi

        # Find the current space with this label
        target_space=$(echo "$current_spaces" | jq -r --arg label "$saved_label" '.[] | select(.label == $label) | .index')

        if [[ -n "$target_space" && "$target_space" != "null" ]]; then
            echo "  Moving window $win_id ($win_app) to space '$saved_label' (index $target_space)"
            yabai -m window "$win_id" --space "$target_space" 2>/dev/null || true
        else
            echo "  Warning: Space '$saved_label' not found for window $win_id ($win_app)"
        fi
    done

    echo "State restored!"

    # Refresh the status bar
    osascript -e 'tell application id "tracesOf.Uebersicht" to refresh widget id "nibar-spaces-jsx"' 2>/dev/null || true
}

show_usage() {
    echo "Usage: $0 [save|restore|reload]"
    echo ""
    echo "Commands:"
    echo "  save     - Save current window and space state"
    echo "  restore  - Restore previously saved state"
    echo "  reload   - Save state, reload yabai, then restore state"
    echo ""
    echo "State is saved to: $STATE_FILE"
}

case "${1:-reload}" in
    save)
        save_state
        ;;
    restore)
        restore_state
        ;;
    reload)
        save_state
        reload_yabai
        restore_state
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
