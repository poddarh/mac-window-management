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

# Fail where the user can actually see it - hotkeys have no terminal
fail() {
    "$YABAI_DIR/lib/notify.sh" "yabai: could not create $label" "$1"
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

# Snapshot existing space ids so the new space can be identified positively
before_ids="$(yabai -m query --spaces --display "$current_display" | jq -c 'map(.id)')"

# Create a new space (creates on the currently focused display)
create_output="$(yabai -m space --create 2>&1)" || fail "${create_output:-yabai -m space --create failed}"

# The scripting addition creates the space asynchronously, so wait for it to
# show up. yabai reports success even when the scripting addition silently does
# nothing (e.g. it could not locate Dock's addSpace function after a macOS
# update), so treat a space that never appears as a hard failure - relabelling
# whatever space happens to be last would steal the label off an existing space.
new_id=""
for _ in $(seq 1 20); do
    new_id="$(yabai -m query --spaces --display "$current_display" | jq -r --argjson before "$before_ids" '
      map(select(.id as $id | $before | index($id) | not)) | .[-1].id // empty
    ')"
    if [[ -n "$new_id" ]]; then
        break
    fi
    sleep 0.1
done

[[ -n "$new_id" ]] || fail "yabai reported success but no space appeared. Check that the scripting addition is loaded: sudo yabai --load-sa"

# Get the index for the newly created space
new_index="$(yabai -m query --spaces --display "$current_display" | jq --argjson id "$new_id" 'map(select(.id == $id))[0].index')"

# Get the index at which the new space should be inserted (sorted by label)
insertion_index="$(yabai -m query --spaces --display "$current_display" | jq --arg label "$label" --argjson fallback "$new_index" '
  [.[] | select(.label != "") | {index: .index, label: .label}]
  | sort_by(.label)
  | map(select(.label > $label))[0].index // $fallback
')"

# Label the new space
label_output="$(yabai -m space "$new_index" --label "$label" 2>&1)" || fail "${label_output:-could not label space $new_index}"

# Move the new space to the right location if needed
if [[ "$new_index" != "$insertion_index" ]]; then
    move_output="$(yabai -m space "$label" --move "$insertion_index" 2>&1)" || fail "${move_output:-could not move $label to index $insertion_index}"
fi
