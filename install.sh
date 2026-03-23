#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Window Manager Setup Installer ==="
echo "This script will install and configure:"
echo "  - Yabai (tiling window manager)"
echo "  - SKHD (hotkey daemon)"
echo "  - Hammerspoon (automation tool)"
echo "  - Übersicht (desktop widgets)"
echo "  - Stackline (window stack indicators)"
echo "  - Nibar (status bar widget)"
echo "  - Karabiner-Elements (keyboard customization)"
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✓ Homebrew found"
fi

# Install tools via Homebrew
echo ""
echo "=== Installing tools via Homebrew ==="

brew install koekeishiya/formulae/yabai || echo "yabai already installed"
brew install koekeishiya/formulae/skhd || echo "skhd already installed"
brew install --cask hammerspoon || echo "hammerspoon already installed"
brew install --cask ubersicht || echo "übersicht already installed"
brew install --cask karabiner-elements || echo "karabiner-elements already installed"

echo ""
echo "=== Creating symlinks ==="

# Backup and link skhdrc
if [ -f "$HOME/.skhdrc" ] && [ ! -L "$HOME/.skhdrc" ]; then
    echo "Backing up existing .skhdrc to .skhdrc.backup"
    mv "$HOME/.skhdrc" "$HOME/.skhdrc.backup"
fi
if [ -L "$HOME/.skhdrc" ]; then
    rm "$HOME/.skhdrc"
fi
ln -s "$SCRIPT_DIR/skhdrc" "$HOME/.skhdrc"
echo "✓ Linked ~/.skhdrc"

# Backup and link yabairc
if [ -f "$HOME/.yabairc" ] && [ ! -L "$HOME/.yabairc" ]; then
    echo "Backing up existing .yabairc to .yabairc.backup"
    mv "$HOME/.yabairc" "$HOME/.yabairc.backup"
fi
if [ -L "$HOME/.yabairc" ]; then
    rm "$HOME/.yabairc"
fi
ln -s "$SCRIPT_DIR/yabairc" "$HOME/.yabairc"
echo "✓ Linked ~/.yabairc"

# Backup and link yabai scripts directory
if [ -d "$HOME/.yabai" ] && [ ! -L "$HOME/.yabai" ]; then
    echo "Backing up existing .yabai/ to .yabai.backup/"
    mv "$HOME/.yabai" "$HOME/.yabai.backup"
fi
if [ -L "$HOME/.yabai" ]; then
    rm "$HOME/.yabai"
fi
ln -s "$SCRIPT_DIR/yabai" "$HOME/.yabai"
echo "✓ Linked ~/.yabai/"

# Create hammerspoon directory if needed
mkdir -p "$HOME/.hammerspoon"

# Backup and link hammerspoon init.lua
if [ -f "$HOME/.hammerspoon/init.lua" ] && [ ! -L "$HOME/.hammerspoon/init.lua" ]; then
    echo "Backing up existing init.lua to init.lua.backup"
    mv "$HOME/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua.backup"
fi
if [ -L "$HOME/.hammerspoon/init.lua" ]; then
    rm "$HOME/.hammerspoon/init.lua"
fi
ln -s "$SCRIPT_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
echo "✓ Linked ~/.hammerspoon/init.lua"

# Initialize and link stackline submodule
echo ""
echo "=== Setting up Stackline ==="
git -C "$SCRIPT_DIR" submodule update --init --recursive

if [ -d "$HOME/.hammerspoon/stackline" ] && [ ! -L "$HOME/.hammerspoon/stackline" ]; then
    echo "Backing up existing stackline/ to stackline.backup/"
    mv "$HOME/.hammerspoon/stackline" "$HOME/.hammerspoon/stackline.backup"
fi
if [ -L "$HOME/.hammerspoon/stackline" ]; then
    rm "$HOME/.hammerspoon/stackline"
fi
ln -s "$SCRIPT_DIR/stackline" "$HOME/.hammerspoon/stackline"
echo "✓ Linked ~/.hammerspoon/stackline/"

# Create Übersicht widgets directory if needed
UBERSICHT_WIDGETS="$HOME/Library/Application Support/Übersicht/widgets"
mkdir -p "$UBERSICHT_WIDGETS"

# Backup and link nibar
if [ -d "$UBERSICHT_WIDGETS/nibar" ] && [ ! -L "$UBERSICHT_WIDGETS/nibar" ]; then
    echo "Backing up existing nibar/ to nibar.backup/"
    mv "$UBERSICHT_WIDGETS/nibar" "$UBERSICHT_WIDGETS/nibar.backup"
fi
if [ -L "$UBERSICHT_WIDGETS/nibar" ]; then
    rm "$UBERSICHT_WIDGETS/nibar"
fi
ln -s "$SCRIPT_DIR/nibar" "$UBERSICHT_WIDGETS/nibar"
echo "✓ Linked Übersicht nibar widget"

# Add Karabiner Caps Lock hyper key rule
echo ""
echo "=== Configuring Karabiner-Elements ==="
"$SCRIPT_DIR/karabiner/install_rule.sh"

echo ""
echo "=== Starting services ==="

# Start yabai and skhd
echo "Starting yabai..."
yabai --start-service || echo "yabai service may already be running"

echo "Starting skhd..."
skhd --start-service || echo "skhd service may already be running"

# Apply macOS defaults (Dock, Desktop, etc.)
"$SCRIPT_DIR/macos/defaults.sh"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "1. Open Hammerspoon and grant Accessibility permissions"
echo "2. Open Übersicht to see the nibar status bar"
echo "3. Open Karabiner-Elements and grant Input Monitoring permissions"
echo "4. You may need to grant Accessibility permissions to yabai"
echo "   Run: sudo yabai --load-sa"
echo "5. For yabai scripting additions, see: https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)"
echo "6. Create a Shortcut for WiFi SSID display (macOS Sonoma+):"
echo "   - Open Shortcuts app"
echo "   - Create new shortcut named 'GetWiFiSSID'"
echo "   - Add action: 'Get Current Wi-Fi'"
echo "   - Add action: 'Stop and Output' (output the Wi-Fi name)"
echo "   - Test with: shortcuts run 'GetWiFiSSID'"
echo ""
echo "To restart services:"
echo "  yabai --restart-service"
echo "  skhd --restart-service"
