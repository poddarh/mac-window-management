#!/bin/bash -ex

die () {
    echo >&2 "$@"
    exit 1
}

# Get all spaces

for i in $(yabai -m query --spaces | jq -r 'map(select(.windows == [] and ."is-visible" == false) | .index) | sort | reverse | join("\n")')
do
    yabai -m space --destroy $i
done
osascript -e 'tell application id "tracesOf.Uebersicht" to refresh widget id "nibar-spaces-jsx"'
