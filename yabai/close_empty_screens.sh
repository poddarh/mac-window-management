#!/bin/bash -ex

die () {
    echo >&2 "$@"
    exit 1
}

# Get sticky window IDs (these appear on all spaces and should be ignored)
sticky_windows=$(yabai -m query --windows | jq '[.[] | select(."is-sticky" == true) | .id]')

# Get all empty, non-visible spaces and destroy them (in reverse order to preserve indices)
# A space is considered empty if it only contains sticky windows
for i in $(yabai -m query --spaces | jq -r --argjson sticky "$sticky_windows" '
    map(select(
        ."is-visible" == false and
        ([.windows[] | select(. as $w | $sticky | index($w) | not)] | length) == 0
    ) | .index) | sort | reverse | .[]
')
do
    yabai -m space --destroy $i
done

# Now fix the ordering of labeled spaces
# Get all labeled spaces on each display, sorted by their numeric label
for display in $(yabai -m query --displays | jq -r '.[].index'); do
    # Get labeled spaces on this display, sorted by numeric label
    labeled_spaces=$(yabai -m query --spaces --display $display | jq -r '
        [.[] | select(.label | test("^space_[0-9]+$")) | {
            index: .index,
            label: .label,
            num: (.label | ltrimstr("space_") | tonumber)
        }] | sort_by(.num)
    ')

    # Get the starting index for this display's spaces
    first_index=$(yabai -m query --spaces --display $display | jq '.[0].index')

    # Move each labeled space to its correct position
    count=$(echo "$labeled_spaces" | jq 'length')
    for ((i=0; i<count; i++)); do
        label=$(echo "$labeled_spaces" | jq -r ".[$i].label")
        target_index=$((first_index + i))

        # Get current index of this space (it may have moved)
        current_index=$(yabai -m query --spaces | jq -r --arg label "$label" '.[] | select(.label == $label) | .index')

        if [[ -n "$current_index" && "$current_index" != "$target_index" ]]; then
            yabai -m space "$label" --move $target_index
        fi
    done
done

osascript -e 'tell application id "tracesOf.Uebersicht" to refresh widget id "nibar-spaces-jsx"'
