#!/usr/bin/env bash

DUMMY_FILE="/tmp/light_mode_active"

systemctl --user stop wlsunset.service wlsunset-manual.service 2>/dev/null
pkill -x wlsunset 2>/dev/null

if [ -f "$DUMMY_FILE" ]; then
  systemd-run --user --unit=wlsunset-auto --collect wlsunset -l 39.56939 -L 2.65024 -t 5500 -T 6500
  sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
  rm -f "$DUMMY_FILE"
else
  systemd-run --user --unit=wlsunset-paper --collect wlsunset -t 6200 -T 6201
  sudo /run/current-system/specialisation/light/bin/switch-to-configuration test
  touch "$DUMMY_FILE"
fi

pkill -x .swaybg-wrapped 2>/dev/null
setsid swaybg -c "$(cat "$HOME/.config/base00")" >/dev/null 2>&1 &

pkill -9 -x .waybar-wrapped 2>/dev/null
while pgrep -x .waybar-wrapped >/dev/null; do sleep 0.1; done
setsid waybar >/dev/null 2>&1 &
