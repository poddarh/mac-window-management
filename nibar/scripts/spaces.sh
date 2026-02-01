#!/bin/sh

PATH=/opt/homebrew/bin/:$PATH
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YABAI_DIR="$HOME/.yabai"
WORKSPACES_CMD="$HOME/.yabai/workspaces.sh"

# Check if yabai exists
if ! [ -x "$(command -v yabai)" ]; then
  echo "{\"error\":\"yabai binary not found\"}"
  exit 1
fi

SPACES=$(yabai -m query --spaces)
DISPLAYS=$(yabai -m query --displays)

# Get focused space label
FOCUSED_SPACE=$(echo "$SPACES" | jq -r '.[] | select(."has-focus") | .label')

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

# Get profile type for active workspace
PROFILE_TYPE="personal"
if [ -x "$WORKSPACES_CMD" ]; then
  PROFILE_TYPE=$("$WORKSPACES_CMD" profile "$ACTIVE_WORKSPACE" 2>/dev/null || echo "personal")
fi

# Get workspace list
WORKSPACE_LIST='["default"]'
if [ -f "$YABAI_DIR/state.json" ]; then
  WORKSPACE_LIST=$(cat "$YABAI_DIR/state.json" | jq '.workspace.list // ["default"]')
fi

echo $(cat <<-EOF
{
  "spaces": $SPACES,
  "displays": $DISPLAYS,
  "activeWorkspace": "$ACTIVE_WORKSPACE",
  "profileType": "$PROFILE_TYPE",
  "workspaces": $WORKSPACE_LIST
}
EOF
)
