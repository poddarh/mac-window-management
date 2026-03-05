# Window Manager Setup

A macOS window management setup using yabai, skhd, and custom tooling with a nibar status bar.

## Features

- **Labeled Spaces**: Up to 10 spaces (space_01 through space_10), auto-created on demand
- **Nibar Status Bar**: Custom Übersicht widgets showing spaces and system status
- **Keyboard-Driven**: Comprehensive hotkey system via skhd
- **State Preservation**: Reload yabai without losing window positions

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Nibar Status Bar                        │
├──────────────────────────────────┬──────────────────────────────┤
│  Spaces                          │   Status (time, etc)         │
│  (left)                          │   (right)                    │
└──────────────────────────────────┴──────────────────────────────┘

Spaces: space_01, space_02, ..., space_10
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
│   │   └── refresh_bar.sh
│   ├── spaces/             # Space operations
│   │   ├── focus.sh        # Focus a space
│   │   ├── move_window.sh  # Move window to space
│   │   ├── create.sh       # Create a space
│   │   └── close_empty.sh  # Clean up empty spaces
│   ├── stacks/             # Stack operations
│   │   └── move.sh         # Move window in stack
│   ├── state.sh            # State persistence
│   └── reload.sh           # Reload yabai with state preservation
├── nibar/                  # Übersicht widgets
│   ├── lib/                # Shared components
│   │   ├── styles.jsx      # Theme and utilities
│   │   ├── Desktop.jsx     # Space rendering
│   │   └── ...
│   ├── spaces.jsx          # Spaces widget
│   ├── status.jsx          # System status
│   └── scripts/            # Data scripts
├── hammerspoon/            # Hammerspoon config
├── karabiner/              # Karabiner rules
├── skhdrc                  # Hotkey definitions
└── yabairc                 # Yabai config
```

## Keyboard Shortcuts

All shortcuts use the **Hyper key** (Caps Lock → Cmd+Ctrl+Alt via Karabiner).

### Navigation

| Shortcut | Action |
|----------|--------|
| Hyper + 1-0 | Focus space 1-10 |
| Hyper + ←/→/↑/↓ | Focus window in direction |
| Hyper + N/P | Focus next/prev space |

### Window Management

| Shortcut | Action |
|----------|--------|
| Shift + Hyper + 1-0 | Move window to space 1-10 |
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

## Configuration

Edit `yabai/lib/config.sh` to customize:
- Widget IDs
- State file paths

## State Management

State is stored in `~/.yabai/state.json`:
- skhd mode (default/resize)

## Dependencies

- [yabai](https://github.com/koekeishiya/yabai) - Tiling window manager
- [skhd](https://github.com/koekeishiya/skhd) - Hotkey daemon
- [Übersicht](http://tracesof.net/uebersicht/) - Desktop widgets
- [Hammerspoon](https://www.hammerspoon.org/) - Automation (for Stackline)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - Keyboard customization
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
