#!/usr/bin/env bash
DUMMY_FILE="/tmp/light_mode_active"
if [ -f "$DUMMY_FILE" ]; then
  cp "$HOME/.nixos-config/config/wallpaper_dark.jpg" "$HOME/.nixos-config/config/wallpaper.jpg"
  sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
  rm -f "$DUMMY_FILE"
else
  cp "$HOME/.nixos-config/config/wallpaper_light.jpg" "$HOME/.nixos-config/config/wallpaper.jpg"
  sudo /run/current-system/specialisation/light/bin/switch-to-configuration test
  touch "$DUMMY_FILE"
fi

swaymsg reload || true
