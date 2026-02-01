#!/bin/bash -e

# Create a space with workspace awareness
# Usage: create.sh <index> [workspace_name]
# - For spaces 01-06: if workspace_name provided, creates "{workspace}_XX", else uses active workspace
# - For spaces 07-10: creates "{profile}_XX" where profile is work/personal based on workspace

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"

die() {
    echo >&2 "$@"
    exit 1
}

# Validate arguments
[ "$#" -ge 1 ] || die "At least 1 argument required, $# provided"
echo "$1" | grep -E -q '^(0[1-9]|10)$' || die "Numeric argument required in the range [01, 10], $1 provided"

index=$1
workspace_prefix=$2

# Determine the label based on space number
if [[ "$index" =~ ^0[1-6]$ ]]; then
    # Workspace-specific space (1-6)
    if [[ -z "$workspace_prefix" ]]; then
        workspace_prefix=$("$YABAI_DIR/state.sh" get 'workspace.active' 2>/dev/null || echo "default")
        if [[ -z "$workspace_prefix" || "$workspace_prefix" == "null" ]]; then
            workspace_prefix="default"
        fi
    fi
    label="${workspace_prefix}_${index}"
else
    # Profile-shared space (7-10)
    if [[ -n "$workspace_prefix" ]]; then
        profile_type=$("$YABAI_DIR/workspaces/manager.sh" profile "$workspace_prefix" 2>/dev/null || echo "personal")
    else
        profile_type=$("$YABAI_DIR/workspaces/manager.sh" profile 2>/dev/null || echo "personal")
    fi
    label="${profile_type}_${index}"
fi

# If a space with that label already exists, then return
if [[ "false" == "$(yabai -m query --spaces | jq --arg label "$label" 'map(select(.label == $label)) == []')" ]]; then
    exit 0
fi

# Get the current display
current_display="$(yabai -m query --spaces | jq 'map(select(."has-focus"))[0].display')"

# Create a new space (creates on the currently focused display)
yabai -m space --create

# Get the index for the newly created space (it's the last space on this display)
new_index="$(yabai -m query --spaces --display "$current_display" | jq '.[-1].index')"

# Get the index at which the new space should be inserted
if [[ "$index" =~ ^0[1-6]$ ]]; then
    # Workspace-specific: find insertion point among all spaces on this display
    insertion_index="$(yabai -m query --spaces --display "$current_display" | jq --arg label "$label" --argjson fallback "$new_index" '
      [.[] | select(.label != "") | {index: .index, label: .label}]
      | sort_by(.label)
      | map(select(.label > $label))[0].index // $fallback
    ')"
else
    # Profile-shared space: use profile_XX pattern
    insertion_index="$(yabai -m query --spaces --display "$current_display" | jq --arg profile "$profile_type" --arg index "$index" --argjson fallback "$new_index" '
      [.[] | select(.label | test("^" + $profile + "_[0-9]+$")) | {index: .index, num: (.label | split("_")[-1] | tonumber)}]
      | map(select(.num > ($index | tonumber)))[0].index // $fallback
    ')"
fi

# Label the new space
yabai -m space "$new_index" --label "$label"

# Move the new space to the right location if needed
if [[ "$new_index" != "$insertion_index" ]]; then
    yabai -m space "$label" --move "$insertion_index"
fi
