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

# --- iTerm2 ---
# Allow terminal apps to access clipboard
defaults write com.googlecode.iterm2 AllowClipboardAccess -bool true
# Disable press-and-hold for key repeat
defaults write com.googlecode.iterm2 ApplePressAndHoldEnabled -bool false
# Manual tab management (don't auto-merge into native tabs)
defaults write com.googlecode.iterm2 AppleWindowTabbingMode -string "manual"
# Disable proxy icon in title bar
defaults write com.googlecode.iterm2 EnableProxyIcon -bool false
# Quit when all windows are closed
defaults write com.googlecode.iterm2 QuitWhenAllWindowsClosed -bool true
# Don't restore windows on launch
defaults write com.googlecode.iterm2 RestoreWindowContents -bool false
# Separate window title per tab
defaults write com.googlecode.iterm2 SeparateWindowTitlePerTab -bool true

echo "✓ iTerm2: clipboard access, key repeat, manual tabs, quit on close"

# iTerm2 Default profile settings (nested in plist)
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [ -f "$ITERM_PLIST" ]; then
    PB=/usr/libexec/PlistBuddy
    # Font: SauceCodePro Nerd Font, size 13
    $PB -c "Set ':New Bookmarks':0:'Normal Font' 'SauceCodeProNF 13'" "$ITERM_PLIST"
    # Scrollback: 20000 lines (default 1000)
    $PB -c "Set ':New Bookmarks':0:'Scrollback Lines' 20000" "$ITERM_PLIST"
    # Disable window resizing when changing font
    $PB -c "Set ':New Bookmarks':0:'Disable Window Resizing' true" "$ITERM_PLIST"
    # Don't prompt before closing sessions
    $PB -c "Set ':New Bookmarks':0:'Prompt Before Closing 2' false" "$ITERM_PLIST"
    # Visual bell instead of audible
    $PB -c "Set ':New Bookmarks':0:'Visual Bell' true" "$ITERM_PLIST"
    echo "✓ iTerm2 profile: SauceCodeProNF 13, 20k scrollback, visual bell"
fi
