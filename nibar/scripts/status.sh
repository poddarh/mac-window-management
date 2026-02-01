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

# WiFi SSID caching to avoid running Shortcut too frequently
# Cache expires after 5 minutes (300 seconds) or when WiFi status changes
WIFI_CACHE_FILE="/tmp/nibar_wifi_ssid_cache"
WIFI_CACHE_MAX_AGE=300

get_wifi_ssid() {
    # Try Shortcuts first (works on macOS Sonoma+)
    local ssid=$(shortcuts run "GetWiFiSSID" 2>/dev/null)
    if [ -z "$ssid" ] || [ "$ssid" = "<redacted>" ]; then
        # Fallback to ipconfig
        ssid=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : '  '/ SSID : / {print $2}' | cut -c -24)
    fi
    if [ "$ssid" = "<redacted>" ]; then
        ssid=""
    fi
    echo "$ssid"
}

WIFI_SSID=""
if [ "$WIFI_STATUS" = "active" ]; then
    # Check if cache exists and is fresh
    if [ -f "$WIFI_CACHE_FILE" ]; then
        CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$WIFI_CACHE_FILE") ))
        if [ "$CACHE_AGE" -lt "$WIFI_CACHE_MAX_AGE" ]; then
            # Use cached value
            WIFI_SSID=$(cat "$WIFI_CACHE_FILE")
        fi
    fi

    # If no valid cache, fetch fresh SSID
    if [ -z "$WIFI_SSID" ]; then
        WIFI_SSID=$(get_wifi_ssid)
        # Save to cache
        echo "$WIFI_SSID" > "$WIFI_CACHE_FILE"
    fi
else
    # WiFi inactive, clear cache
    rm -f "$WIFI_CACHE_FILE" 2>/dev/null
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
