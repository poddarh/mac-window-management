#!/bin/sh

PATH=/opt/homebrew/bin/:$PATH
YABAI_DIR="$HOME/.yabai"

# Get focused space label
FOCUSED_SPACE=$(yabai -m query --spaces 2>/dev/null | jq -r '.[] | select(."has-focus") | .label')

# Derive active workspace from focused space if it's a workspace-specific space
# Pattern: {workspace}_0[1-6]
if echo "$FOCUSED_SPACE" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*_0[1-6]$'; then
  # Extract workspace name (everything before _0X)
  ACTIVE_WORKSPACE=$(echo "$FOCUSED_SPACE" | sed 's/_0[1-6]$//')
else
  # On a shared space - use stored state
  ACTIVE_WORKSPACE="default"
  if [ -f "$YABAI_DIR/state.json" ]; then
    ACTIVE_WORKSPACE=$(cat "$YABAI_DIR/state.json" | jq -r '.workspace.active // "default"')
  fi
fi

# Get workspace list
WORKSPACE_LIST='["default"]'
if [ -f "$YABAI_DIR/state.json" ]; then
  WORKSPACE_LIST=$(cat "$YABAI_DIR/state.json" | jq '.workspace.list // ["default"]')
fi

echo $(cat <<-EOF
{
  "activeWorkspace": "$ACTIVE_WORKSPACE",
  "workspaces": $WORKSPACE_LIST
}
EOF
)
