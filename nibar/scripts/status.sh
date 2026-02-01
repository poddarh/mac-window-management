#!/bin/bash

PATH=/opt/homebrew/bin/:$PATH

export LC_TIME="en_US.UTF-8"
TIME=$(date +"%H:%M")
DATE=$(date +"%a %m/%d")

BATTERY_PERCENTAGE=$(pmset -g batt | egrep '([0-9]+\%).*' -o --colour=auto | cut -f1 -d'%')
BATTERY_STATUS=$(pmset -g batt | grep "'.*'" | sed "s/'//g" | cut -c 18-19)
BATTERY_REMAINING=$(pmset -g batt | egrep -o '([0-9]+%).*' | cut -d\  -f3)

BATTERY_CHARGING=""
if [ "$BATTERY_STATUS" == "Ba" ]; then
  BATTERY_CHARGING="false"
elif [ "$BATTERY_STATUS" == "AC" ]; then
  BATTERY_CHARGING="true"
fi

LOAD_AVERAGE=$(sysctl -n vm.loadavg | awk '{print $2}')

WIFI_STATUS=$(ifconfig en0 | grep status | cut -c 10-)

# Try to get WiFi SSID using Shortcuts (works on macOS Sonoma+)
# Requires a Shortcut named "GetWiFiSSID" that outputs the network name
# Fallback to ipconfig if Shortcut doesn't exist
WIFI_SSID=$(shortcuts run "GetWiFiSSID" 2>/dev/null)
if [ -z "$WIFI_SSID" ] || [ "$WIFI_SSID" = "<redacted>" ]; then
    # Fallback to ipconfig (may show <redacted> without Location Services)
    WIFI_SSID=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : '  '/ SSID : / {print $2}' | cut -c -24)
fi
# If still redacted or empty, just show WiFi icon
if [ "$WIFI_SSID" = "<redacted>" ]; then
    WIFI_SSID=""
fi

YABAI_DIR="$HOME/.yabai"

# Get skhd mode from state.json (with fallback to legacy file during migration)
SKHD_MODE="default"
if [ -f "$YABAI_DIR/state.json" ]; then
    SKHD_MODE=$(cat "$YABAI_DIR/state.json" | jq -r '.skhd.mode // "default"')
elif [ -f "$HOME/.skhd_state" ]; then
    SKHD_MODE=$(cat ~/.skhd_state)
fi

YABAI_ACTIVE_WINDOW=$(yabai -m query --windows --window 2>/dev/null || echo null)

# DND=$(defaults -currentHost read com.apple.notificationcenterui doNotDisturb)

MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

echo $(cat <<-EOF
{
    "datetime": {
        "time": "$TIME",
        "date": "$DATE"
    },
    "battery": {
        "percentage": $BATTERY_PERCENTAGE,
        "charging": $BATTERY_CHARGING,
        "remaining": "$BATTERY_REMAINING"
    },
    "cpu": {
        "loadAverage": $LOAD_AVERAGE
    },
    "wifi": {
        "status": "$WIFI_STATUS",
        "ssid":  "$WIFI_SSID"
    },
    "mic": $MIC_VOLUME,
    "skhd_mode": "$SKHD_MODE",
    "yabai_active_window": $YABAI_ACTIVE_WINDOW
}
EOF
)
