#!/usr/bin/env bash
entries="󰖨  Day\n󰛨  Night\n󰖔  Midnight"
selected=$(echo -e "$entries" | rofi -dmenu -i -p "Temperature" -theme-str 'window { width: 300px; } listview { lines: 3; }')

[ -z "$selected" ] && exit 0 # Exit if the user pressed Escape
systemctl --user stop wlsunset.service wlsunset-manual.service 2>/dev/null
systemctl --user reset-failed wlsunset-manual.service 2>/dev/null
pkill -x wlsunset
sleep 0.1

case "$selected" in
  *"Day"*)
    systemctl --user start wlsunset.service
    ;;
  *"Night"*)
    systemd-run --user --unit=wlsunset-manual wlsunset -t 5000 -T 5001
    ;;
  *"Midnight"*)
    systemd-run --user --unit=wlsunset-manual wlsunset -t 4000 -T 4001
    ;;
esac
