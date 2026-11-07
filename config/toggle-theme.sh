#!/usr/bin/env bash
DUMMY_FILE="/tmp/light_mode_active"
if [ -f "$DUMMY_FILE" ]; then
  systemctl --user stop wlsunset.service wlsunset-manual.service 2>/dev/null
  pkill -x wlsunset 2>/dev/null
  systemd-run --user --unit=wlsunset-auto --collect wlsunset -l 39.56939 -L 2.65024 -t 5500 -T 6500
  sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
  rm -f "$DUMMY_FILE"
else
  systemctl --user stop wlsunset.service wlsunset-manual.service 2>/dev/null
  pkill -x wlsunset 2>/dev/null
  systemd-run --user --unit=wlsunset-paper --collect wlsunset -t 6200 -T 6201
  sudo /run/current-system/specialisation/light/bin/switch-to-configuration test
  touch "$DUMMY_FILE"
fi

swaymsg reload || true
