#!/usr/bin/env bash
entries="󰐥 Poweroff\n󰤄 Suspend\n󰜉 Reboot\n󰈆 Log out"
selected=$(echo -e "$entries" | rofi -dmenu -i -p "Power" -theme-str 'window { width: 150px; } listview { lines: 4; }')
case "$selected" in
  *"Poweroff") systemctl poweroff ;;
  *"Suspend") waylock -fork-on-lock -init-color 0x000000 -input-color 0x221E1B -input-alt-color 0x221E1B && systemctl suspend ;;
  *"Reboot") systemctl reboot ;;
  *"Log out") mmsg dispatch quit ;;
esac
