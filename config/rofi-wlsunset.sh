#!/usr/bin/env bash
entries="󰖨  Auto\n  Off\n  Paper\n󰛨  Night\n󰖔  Midnight"
selected=$(echo -e "$entries" | rofi -dmenu -i -p "Temperature" -theme-str 'window { width: 160px; } listview { lines: 5; }')

[ -z "$selected" ] && exit 0 # Exit if the user pressed Escape
systemctl --user stop wlsunset.service wlsunset-manual.service 2>/dev/null
pkill -x wlsunset 2>/dev/null

case "$selected" in
  *"Auto"*) systemd-run --user --unit=wlsunset-auto --collect wlsunset -l 39.56939 -L 2.65024 -t 5500 -T 6500 ;;
  *"Off"*) systemctl --user start wlsunset.service ;;
  *"Paper"*) systemd-run --user --unit=wlsunset-paper --collect wlsunset -t 6200 -T 6201 ;;
  *"Night"*) systemd-run --user --unit=wlsunset-night --collect wlsunset -t 5000 -T 5001 ;;
  *"Midnight"*) systemd-run --user --unit=wlsunset-midnight --collect wlsunset -t 4000 -T 4001 ;;
esac
