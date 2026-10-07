#!/bin/bash

# Report an error both to stderr and as a macOS notification.
# Scripts bound to skhd hotkeys have no terminal, so stderr alone is invisible.
# Usage: notify.sh <title> <message>

title="$1"
message="$2"

echo "$title: $message" >&2

escape() {
    local s="${1//\\/\\\\}"
    echo "${s//\"/\\\"}"
}

osascript -e "display notification \"$(escape "$message")\" with title \"$(escape "$title")\"" 2>/dev/null || true
