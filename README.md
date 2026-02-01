# Window Manager Setup

A comprehensive macOS window management setup using yabai, skhd, and custom tooling for virtual workspaces with Chrome profile integration.

## Features

- **Virtual Workspaces**: Multiple workspaces with 6 dedicated spaces each (spaces 1-6)
- **Profile-Shared Spaces**: Spaces 7-10 are shared across workspaces of the same profile type (work/personal)
- **Chrome Profile Routing**: URLs automatically open in the correct Chrome profile based on active workspace
- **Nibar Status Bar**: Custom Übersicht widgets showing spaces, workspaces, and system status
- **Keyboard-Driven**: Comprehensive hotkey system via skhd

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Nibar Status Bar                        │
├──────────────┬────────────────────────┬────────────────────────┤
│  Spaces      │   Workspace Switcher   │   Status (time, etc)   │
│  (left)      │   (center)             │   (right)              │
└──────────────┴────────────────────────┴────────────────────────┘

Workspaces:
  personal          work              testing
  ├── personal_01   ├── work_01       ├── testing_01
  ├── personal_02   ├── work_02       ├── testing_02
  ├── ...           ├── ...           ├── ...
  └── personal_06   └── work_06       └── testing_06

Shared Spaces (by profile type):
  work_07, work_08, work_09, work_10      (shared across all work workspaces)
  personal_07, personal_08, personal_09   (shared across all personal workspaces)
```

## Installation

```bash
./install.sh
```

This will:
- Symlink configuration files to appropriate locations
- Set up Karabiner-Elements (Caps Lock → Hyper key)
- Configure yabai and skhd
- Set up nibar widgets

## Directory Structure

```
├── yabai/                  # Yabai scripts
│   ├── lib/                # Shared utilities
│   │   ├── config.sh       # Central configuration
│   │   ├── get_space_label.sh
│   │   ├── refresh_bar.sh
│   │   └── select_workspace_dialog.sh
│   ├── spaces/             # Space operations
│   │   ├── focus.sh        # Focus a space
│   │   ├── move_window.sh  # Move window to space
│   │   ├── create.sh       # Create a space
│   │   └── close_empty.sh  # Clean up empty spaces
│   ├── stacks/             # Stack operations
│   │   └── move.sh         # Move window in stack
│   ├── workspaces/         # Workspace management
│   │   ├── manager.sh      # Main workspace commands
│   │   ├── sync.sh         # Sync workspace state
│   │   ├── move_window_dialog.sh
│   │   └── move_space_dialog.sh
│   ├── state.sh            # State persistence
│   ├── reload.sh           # Reload yabai with state preservation
│   └── open_chrome.sh      # Open Chrome with correct profile
├── alfred-workflow/        # Alfred workflow source
│   ├── info.plist          # Workflow definition
│   └── icon.png            # Workflow icon
├── nibar/                  # Übersicht widgets
│   ├── lib/                # Shared components
│   │   ├── styles.jsx      # Theme and utilities
│   │   ├── Desktop.jsx     # Space rendering
│   │   └── ...
│   ├── spaces.jsx          # Spaces widget
│   ├── workspace.jsx       # Workspace switcher
│   ├── status.jsx          # System status
│   └── scripts/            # Data scripts
├── hammerspoon/            # Hammerspoon config
├── karabiner/              # Karabiner rules
├── skhdrc                  # Hotkey definitions
├── yabairc                 # Yabai config
└── finicky.js              # URL routing
```

## Keyboard Shortcuts

All shortcuts use the **Hyper key** (Caps Lock → Cmd+Ctrl+Alt via Karabiner).

### Navigation

| Shortcut | Action |
|----------|--------|
| Hyper + 1-6 | Focus space 1-6 (workspace-specific) |
| Hyper + 7-0 | Focus space 7-10 (profile-shared) |
| Hyper + W | Cycle workspaces |
| Hyper + ←/→/↑/↓ | Focus window in direction |
| Hyper + N/P | Focus next/prev space |

### Window Management

| Shortcut | Action |
|----------|--------|
| Shift + Hyper + 1-6 | Move window to space 1-6 |
| Shift + Hyper + 7-0 | Move window to space 7-10 |
| Shift + Hyper + W | Move window to another workspace (dialog) |
| Shift + Hyper + M | Move space to another workspace (dialog) |
| Shift + Hyper + ←/→/↑/↓ | Warp window in direction |
| Hyper + F | Toggle fullscreen zoom |
| Hyper + = | Balance window sizes |

### Stack Navigation

| Shortcut | Action |
|----------|--------|
| Hyper + S | Toggle stack insertion mode |
| Hyper + [ / ] | Focus prev/next in stack |
| Shift + Hyper + H/J/K/L | Stack window in direction |

### Other

| Shortcut | Action |
|----------|--------|
| Hyper + R | Enter resize mode |
| Hyper + Return | Open terminal |
| Shift + Hyper + Q | Close window |
| Shift + Hyper + R | Reload yabai (preserves state) |

## Workspace Profiles

Workspaces can be either **work** or **personal** profile:
- Determines which Chrome profile opens for URLs
- Spaces 7-10 are shared within the same profile type
- Profile colors: Blue (work), Green (personal)

## Chrome Integration

### Finicky (URL Routing)
URLs clicked anywhere on the system open in the Chrome profile matching the active workspace's profile type.

### Alfred Workflow
Keyword `chrome` opens Chrome in the correct profile, focusing an existing window on the workspace if available.

## Configuration

Edit `yabai/lib/config.sh` to customize:
- Chrome profile directories
- Widget IDs
- State file paths

## State Management

Workspace state is stored in `~/.yabai/state.json`:
- Active workspace
- Workspace list
- Profile mappings
- Last focused space per workspace

## Dependencies

- [yabai](https://github.com/koekeishiya/yabai) - Tiling window manager
- [skhd](https://github.com/koekeishiya/skhd) - Hotkey daemon
- [Übersicht](http://tracesof.net/uebersicht/) - Desktop widgets
- [Hammerspoon](https://www.hammerspoon.org/) - Automation (for Stackline)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - Keyboard customization
- [Finicky](https://github.com/johnste/finicky) - URL routing
- [jq](https://stedolan.github.io/jq/) - JSON processing

## WiFi SSID Display (macOS Sonoma+)

macOS Sonoma restricts access to WiFi network names for privacy. To display the WiFi SSID in the status bar, create a Shortcut:

1. Open **Shortcuts** app
2. Create a new shortcut named exactly: `GetWiFiSSID`
3. Add action: **Get Current Wi-Fi**
4. Add action: **Stop and Output** (set to output the Wi-Fi name)
5. Save the shortcut

Test it works:
```bash
shortcuts run "GetWiFiSSID"
```

If the shortcut doesn't exist, the status bar will show just a WiFi icon without the network name.
