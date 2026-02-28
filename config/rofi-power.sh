#!/usr/bin/env bash
entries="󰐥 Poweroff\n󰤄 Suspend\n󰜉 Reboot\n󰈆 Log out"
selected=$(echo -e "$entries" | rofi -dmenu -i -p "Power" -theme-str 'window { width: 300px; } listview { lines: 4; }')
case "$selected" in
  *"Poweroff") systemctl poweroff ;;
  *"Suspend") systemctl suspend ;;
  *"Reboot") systemctl reboot ;;
  *"Log out") swaymsg exit ;;
esac
