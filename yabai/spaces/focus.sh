#!/bin/bash

# Focus a space by number
# Usage: focus.sh <space_number>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YABAI_DIR="$(dirname "$SCRIPT_DIR")"
source "$YABAI_DIR/lib/get_space_label.sh"

space_num=$1

if [[ -z "$space_num" ]]; then
    echo "Usage: focus.sh <space_number>"
    exit 1
fi

# Get the label for this space
label=$(get_space_label "$space_num")

# Ensure space exists
"$SCRIPT_DIR/create.sh" "$space_num"

# Focus the space
yabai -m space --focus "$label"

# Notify bar
"$YABAI_DIR/lib/refresh_bar.sh" spaces
