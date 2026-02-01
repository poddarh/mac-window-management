#!/bin/bash

# Focus a space with workspace awareness
# Usage: focus.sh <space_number>
# For spaces 1-6: focuses {active_workspace}_0N
# For spaces 7-10: focuses {profile}_0N where profile is work/personal

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/config.sh"
source "$YABAI_DIR/lib/get_space_label.sh"

space_num=$1

if [[ -z "$space_num" ]]; then
    echo "Usage: focus.sh <space_number>"
    exit 1
fi

# Get the proper label for this space
label=$(get_space_label "$space_num")

# Ensure space exists
"$SCRIPT_DIR/create.sh" "$space_num"

# Focus the space
yabai -m space --focus "$label"

# Notify bar
"$YABAI_DIR/lib/refresh_bar.sh" spaces
