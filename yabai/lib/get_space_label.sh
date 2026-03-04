#!/bin/bash

# Get the space label for a given space number
# Usage: source this file, then call get_space_label <space_num>
# Returns the label via echo (capture with $(get_space_label ...))

get_space_label() {
    echo "space_$1"
}
