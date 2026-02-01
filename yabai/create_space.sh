#!/bin/bash -ex

die () {
    echo >&2 "$@"
    exit 1
}

# Valudate the index argument
[ "$#" -eq 1 ] || die "1 argument required, $# provided"
echo $1 | grep -E -q '^(0[1-9]|10)$' || die "Numeric argument required in the range [01, 10], $1 provided"

# Name the first argument
index=$1

# If a space with that name already exists, then return
if [[ "false" == "$(yabai -m query --spaces | jq --arg index "space_$index" 'map(select(.label == $index)) == []')" ]]; then
	exit 0
fi

# Get the current display
current_display="$(yabai -m query --spaces | jq 'map(select(."has-focus"))[0].display')"

# Create a new space (creates on the currently focused display)
yabai -m space --create

# Get the index for the newly created space (it's the last space on this display)
new_index="$(yabai -m query --spaces --display $current_display | jq '.[-1].index')"

# Get the index at which the new space should be inserted
# Extract numeric suffix for proper numeric comparison (string comparison fails for space_09 vs space_10)
# If no space with a larger label exists, use new_index (no move needed)
insertion_index="$(yabai -m query --spaces --display $current_display | jq --arg index "$index" --argjson fallback "$new_index" '
  [.[] | select(.label | test("^space_[0-9]+$")) | {index: .index, num: (.label | ltrimstr("space_") | tonumber)}]
  | map(select(.num > ($index | tonumber)))[0].index // $fallback
')"

# Move the new space in the right location
yabai -m space $new_index --label "space_$index"

if [[ $new_index != $insertion_index ]]; then
	yabai -m space "space_$index" --move $insertion_index
fi
