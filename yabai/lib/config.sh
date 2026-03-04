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
# Ubersicht / Nibar Configuration
# ============================================================

UBERSICHT_APP_ID="tracesOf.Uebersicht"

# Widget IDs
NIBAR_WIDGET_SPACES="nibar-spaces-jsx"
NIBAR_WIDGET_STATUS="nibar-status-jsx"
NIBAR_WIDGET_BAR="nibar-bar-jsx"

# ============================================================
# Homebrew Path
# ============================================================

# Ensure homebrew binaries are in PATH
export PATH="/opt/homebrew/bin:$PATH"
