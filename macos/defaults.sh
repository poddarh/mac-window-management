#!/bin/bash
#
# macOS defaults configuration
# Applies system preferences via `defaults write` commands.
#

set -e

echo "=== Configuring macOS defaults ==="

# --- Dock ---
# Auto-hide the dock
defaults write com.apple.dock autohide -bool true
# Remove dock auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
# Speed up dock hide/show animation
defaults write com.apple.dock autohide-time-modifier -float 0.5

killall Dock
echo "✓ Dock: auto-hide enabled, no delay, faster animation"

# --- Finder ---
# Show path bar at bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true
# Default to list view in Finder
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

killall Finder
echo "✓ Finder: path bar enabled, list view default"

# --- Appearance ---
# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Don't minimize windows on double-click title bar
defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false

echo "✓ Appearance: dark mode, show extensions, no minimize on double-click"

# --- Sound ---
# Mute system alert sound
defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0

echo "✓ Sound: alert volume muted"

# --- Desktop / Window Manager ---
# Disable "Click wallpaper to reveal desktop" (macOS Sonoma+)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
# Hide desktop items when showing windows
defaults write com.apple.WindowManager HideDesktop -bool true

echo "✓ Desktop: click-to-reveal disabled, desktop items hidden"

# --- Menu Bar ---
# Hide date in menu bar clock
defaults write com.apple.menuextra.clock ShowDate -int 0

echo "✓ Menu bar: date hidden from clock"
