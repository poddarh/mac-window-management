#!/bin/bash

# Refresh nibar widgets
# Usage: refresh_bar.sh [widget...]
#   No args: refresh all widgets (spaces, workspace, status)
#   spaces: refresh spaces widget only
#   workspace: refresh workspace widget only
#   status: refresh status widget only
#   bar: refresh bar widget only

UBERSICHT_APP_ID="tracesOf.Uebersicht"

# Widget IDs
WIDGET_SPACES="nibar-spaces-jsx"
WIDGET_WORKSPACE="nibar-workspace-jsx"
WIDGET_STATUS="nibar-status-jsx"
WIDGET_BAR="nibar-bar-jsx"

refresh_widget() {
    local widget_id="$1"
    osascript -e "tell application id \"$UBERSICHT_APP_ID\" to refresh widget id \"$widget_id\"" 2>/dev/null || true
}

# If no arguments, refresh spaces and workspace (most common case)
if [[ $# -eq 0 ]]; then
    refresh_widget "$WIDGET_SPACES"
    refresh_widget "$WIDGET_WORKSPACE"
    exit 0
fi

# Refresh specified widgets
for widget in "$@"; do
    case "$widget" in
        spaces)
            refresh_widget "$WIDGET_SPACES"
            ;;
        workspace)
            refresh_widget "$WIDGET_WORKSPACE"
            ;;
        status)
            refresh_widget "$WIDGET_STATUS"
            ;;
        bar)
            refresh_widget "$WIDGET_BAR"
            ;;
        all)
            refresh_widget "$WIDGET_SPACES"
            refresh_widget "$WIDGET_WORKSPACE"
            refresh_widget "$WIDGET_STATUS"
            refresh_widget "$WIDGET_BAR"
            ;;
        *)
            echo "Unknown widget: $widget" >&2
            echo "Usage: refresh_bar.sh [spaces|workspace|status|bar|all]" >&2
            exit 1
            ;;
    esac
done
