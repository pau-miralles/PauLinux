#!/usr/bin/env bash
BAT_PATH="/sys/class/power_supply/BAT1"

while true; do
    if [ -f "$BAT_PATH/capacity" ]; then
        BAT=$(cat "$BAT_PATH/capacity")
        STAT=$(cat "$BAT_PATH/status")

        if [ "$BAT" -le 20 ] && [ "$STAT" = "Discharging" ]; then
            notify-send -u critical "LOW BATTERY"
            notify-send -u critical "LOW BATTERY"
            notify-send -u critical "LOW BATTERY"
            brightnessctl set 20%
            powerprofilesctl set power-saver
            sleep 600 # Sleep to avoid spamming while low
        fi
    fi
    sleep 60
done
