#!/usr/bin/env bash
if [ ! -f /tmp/theme_state ] || [ "$(cat /tmp/theme_state)" = "dark" ]; then
  sudo /run/current-system/specialisation/light/bin/switch-to-configuration test
  echo "light" > /tmp/theme_state
else
  sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
  echo "dark" > /tmp/theme_state
fi

killall -SIGUSR1 kitty || true
swaymsg reload || true
