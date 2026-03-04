# Project Instructions for Claude

## Git Workflow

- **Always ask before making any commits.** Do not commit changes without explicit user approval.
- Stage changes and show what will be committed, then wait for confirmation before running `git commit`.

## Yabai Management

- **Always use `~/.yabai/reload.sh` to restart yabai.** This script saves and restores window state so windows, spaces, and positions are preserved across restarts.
- Never use `yabai --restart-service` directly as it will lose window positions.

## Directory Structure

```
yabai/
├── lib/                    # Shared utilities
│   ├── config.sh           # Central config (widget IDs, paths)
│   ├── get_space_label.sh  # Get label for a space number (space_01, space_02, etc.)
│   └── refresh_bar.sh      # Refresh nibar widgets
├── spaces/                 # Space operations
│   ├── focus.sh            # Focus a space by number
│   ├── move_window.sh      # Move window to space
│   ├── create.sh           # Create a new space
│   └── close_empty.sh      # Clean up empty spaces
├── stacks/                 # Stack operations
│   └── move.sh             # Navigate within stacks
├── state.sh                # State persistence (get/set for ~/.yabai/state.json)
└── reload.sh               # Reload yabai with state preservation
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `state.sh get <path>` | Get value from state.json (e.g., `state.sh get skhd.mode`) |
| `state.sh set <path> <value>` | Set value in state.json |
| `lib/refresh_bar.sh <widgets...>` | Refresh nibar widgets (spaces, status) |

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
```

## Testing Changes

| Component | How to Test |
|-----------|-------------|
| Yabai config | `~/.yabai/reload.sh` (preserves state) |
| skhd hotkeys | `skhd --restart-service` |
| Nibar widgets | Refresh Übersicht app or edit widget file |
| Scripts | Run directly from terminal with debug: `bash -x ~/.yabai/script.sh` |
