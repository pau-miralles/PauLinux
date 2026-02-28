#!/usr/bin/env bash
entries="󰖨  Day\n󰛨  Night\n󰖔  Midnight"
selected=$(echo -e "$entries" | rofi -dmenu -i -p "Temperature" -theme-str 'window { width: 300px; } listview { lines: 3; }')
pkill -x wlsunset
sleep 0.1
case "$selected" in
  *"Day"*)
    systemctl --user start wlsunset.service
    ;;
  *"Night"*)
    systemd-run --user --unit=wlsunset-manual wlsunset -t 5000 -T 6500
    ;;
  *"Midnight"*)
    systemd-run --user --unit=wlsunset-manual wlsunset -t 4000 -T 6500
    ;;
esac
