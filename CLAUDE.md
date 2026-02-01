# Project Instructions for Claude

## Git Workflow

- **Always ask before making any commits.** Do not commit changes without explicit user approval.
- Stage changes and show what will be committed, then wait for confirmation before running `git commit`.

## Yabai Management

- **Always use `~/.yabai/reload.sh` to restart yabai.** This script saves and restores window state so windows, spaces, and workspaces are preserved across restarts.
- Never use `yabai --restart-service` directly as it will lose window positions and workspace state.

## Directory Structure

```
yabai/
├── lib/                    # Shared utilities
│   ├── config.sh           # Central config (Chrome profiles, widget IDs)
│   ├── get_space_label.sh  # Get label for a space number
│   ├── refresh_bar.sh      # Refresh nibar widgets
│   └── select_workspace_dialog.sh
├── spaces/                 # Space operations
│   ├── focus.sh            # Focus a space by number
│   ├── move_window.sh      # Move window to space
│   ├── create.sh           # Create a new space
│   └── close_empty.sh      # Clean up empty spaces
├── stacks/                 # Stack operations
│   └── move.sh             # Navigate within stacks
├── workspaces/             # Workspace management
│   ├── manager.sh          # Main workspace commands (list, active, switch, create, delete, profile)
│   ├── sync.sh             # Sync workspace state on space change
│   ├── move_window_dialog.sh
│   └── move_space_dialog.sh
├── state.sh                # State persistence (get/set for ~/.yabai/state.json)
├── reload.sh               # Reload yabai with state preservation
└── open_chrome.sh          # Open Chrome with correct profile for workspace
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `workspaces/manager.sh <cmd>` | Workspace CRUD: `list`, `active`, `switch <name>`, `create <name>`, `delete <name>`, `profile <name>` |
| `state.sh get <path>` | Get value from state.json (e.g., `state.sh get workspace.active`) |
| `state.sh set <path> <value>` | Set value in state.json |
| `open_chrome.sh [url]` | Open Chrome in correct profile, reuse window if on workspace |
| `lib/refresh_bar.sh <widgets...>` | Refresh nibar widgets (spaces, workspace, status) |

## Chrome Integration

- **Profile types**: `work` or `personal`, configured per workspace in state.json
- **Profile directories**: Set in `lib/config.sh` (`CHROME_PROFILE_WORK`, `CHROME_PROFILE_PERSONAL`)
- **Window detection**: Filters by `role == "AXWindow"` to exclude tooltips/helpers
- **Behavior**: Reuses existing Chrome window on workspace, creates new one if none exists

## Übersicht/Nibar Notes

- Widget files are in `nibar/` directory
- **Uses Nerd Font icons** (SauceCodePro Nerd Font), NOT SF Symbols
- Icons are Font Awesome glyphs embedded as UTF-8 (e.g., U+F1EB for WiFi)
- Refresh widgets: `osascript -e 'tell application "Übersicht" to refresh'` or click Übersicht menu

## Debugging Commands

```bash
# Query current space
yabai -m query --spaces --space | jq '{index, label}'

# Query all spaces
yabai -m query --spaces | jq '.[] | {index, label}'

# Query all windows with details
yabai -m query --windows | jq '.[] | {id, app, space, title: .title[0:50], role}'

# Find Chrome windows (real windows only)
yabai -m query --windows | jq '.[] | select(.app == "Google Chrome" and .role == "AXWindow")'

# Get current workspace
~/.yabai/workspaces/manager.sh active

# Get workspace profile type
~/.yabai/workspaces/manager.sh profile <workspace_name>
```

## Testing Changes

| Component | How to Test |
|-----------|-------------|
| Yabai config | `~/.yabai/reload.sh` (preserves state) |
| skhd hotkeys | `skhd --restart-service` |
| Nibar widgets | Refresh Übersicht app or edit widget file |
| Scripts | Run directly from terminal with debug: `bash -x ~/.yabai/script.sh` |
