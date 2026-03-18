#!/usr/bin/env bash
STATE_FILE="/tmp/sway_dim_active"
if [ -f "$STATE_FILE" ]; then
    NEW_VAL="0.0"
    rm -f "$STATE_FILE"
else
    NEW_VAL="0.15"
    touch "$STATE_FILE"
fi

swaymsg "default_dim_inactive $NEW_VAL"
swaymsg "[app_id=\".*\"] dim_inactive $NEW_VAL"
swaymsg "[class=\".*\"] dim_inactive $NEW_VAL"
