#!/bin/bash -e

# Create a space with a given index
# Usage: create.sh <index>
# Labels the space as "space_XX" (e.g., space_01, space_10)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"

die() {
    echo >&2 "$@"
    exit 1
}

# Validate arguments
[ "$#" -ge 1 ] || die "At least 1 argument required, $# provided"
echo "$1" | grep -E -q '^(0[1-9]|10)$' || die "Numeric argument required in the range [01, 10], $1 provided"

index=$1
label="space_${index}"

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

# Get the index at which the new space should be inserted (sorted by label)
insertion_index="$(yabai -m query --spaces --display "$current_display" | jq --arg label "$label" --argjson fallback "$new_index" '
  [.[] | select(.label != "") | {index: .index, label: .label}]
  | sort_by(.label)
  | map(select(.label > $label))[0].index // $fallback
')"

# Label the new space
yabai -m space "$new_index" --label "$label"

# Move the new space to the right location if needed
if [[ "$new_index" != "$insertion_index" ]]; then
    yabai -m space "$label" --move "$insertion_index"
fi
