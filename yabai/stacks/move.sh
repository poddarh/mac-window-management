#!/usr/bin/env bash
# Move window within stack (next or prev)
# Usage: move.sh next|prev

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

direction="${1:-next}"

win_id=$(yabai -m query --windows --window | jq '.id')
yabai -m window --swap "stack.$direction"
yabai -m window --focus "$win_id"
hs -c 'stackline.manager:cleanup(); stackline.manager:update({forceRedraw = true})'
