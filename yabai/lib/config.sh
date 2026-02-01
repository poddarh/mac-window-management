#!/bin/bash

# Central configuration for window-manager-setup
# Source this file in scripts that need configuration values

# ============================================================
# Paths
# ============================================================

# Yabai state directory
YABAI_STATE_DIR="$HOME/.yabai"
YABAI_STATE_FILE="$YABAI_STATE_DIR/state.json"

# Temporary state file for yabai restarts
YABAI_TEMP_STATE="/tmp/yabai_state.json"

# ============================================================
# Chrome Configuration
# ============================================================

# Chrome profile directories (relative to ~/Library/Application Support/Google/Chrome/)
CHROME_PROFILE_WORK="Default"
CHROME_PROFILE_PERSONAL="Profile 10"

# Map profile type to Chrome profile directory
get_chrome_profile() {
    local profile_type="$1"
    case "$profile_type" in
        work)
            echo "$CHROME_PROFILE_WORK"
            ;;
        personal|*)
            echo "$CHROME_PROFILE_PERSONAL"
            ;;
    esac
}

# ============================================================
# Ubersicht / Nibar Configuration
# ============================================================

UBERSICHT_APP_ID="tracesOf.Uebersicht"

# Widget IDs
NIBAR_WIDGET_SPACES="nibar-spaces-jsx"
NIBAR_WIDGET_WORKSPACE="nibar-workspace-jsx"
NIBAR_WIDGET_STATUS="nibar-status-jsx"
NIBAR_WIDGET_BAR="nibar-bar-jsx"

# ============================================================
# Space Naming Configuration
# ============================================================

# Workspace-specific spaces: 01-06
# Profile-shared spaces: 07-10

# Regex patterns for space labels
WORKSPACE_SPACE_PATTERN='_0[1-6]$'
SHARED_SPACE_PATTERN='_0[7-9]$|_10$'

# ============================================================
# Homebrew Path
# ============================================================

# Ensure homebrew binaries are in PATH
export PATH="/opt/homebrew/bin:$PATH"
