#!/usr/bin/env bash

STATE_FILE="/tmp/sway_dim_state"

if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" == "on" ]; then
    NEW_VAL="0.0"
    echo "off" > "$STATE_FILE"
else
    NEW_VAL="0.15"
    echo "on" > "$STATE_FILE"
fi
swaymsg "default_dim_inactive $NEW_VAL"
# Apply to all current windows
swaymsg "[app_id=\".*\"] dim_inactive $NEW_VAL"
swaymsg "[class=\".*\"] dim_inactive $NEW_VAL"
