#!/usr/bin/env bash
win_id=$(yabai -m query --windows --window | jq '.id')
yabai -m window --swap stack.next
yabai -m window --focus $win_id
hs -c 'stackline.manager:cleanup(); stackline.manager:update({forceRedraw = true})'
