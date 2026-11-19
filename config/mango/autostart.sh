swaybg -c "$(cat "$HOME/.config/base00")" &
waybar &
swayidle -w timeout 300 'systemctl suspend' before-sleep 'waylock -fork-on-lock -init-color 0x000000 -input-color 0x221E1B -input-alt-color 0x221E1B' &
low-battery-warning &
systemd-run --user --unit=wlsunset-auto --collect wlsunset -l 39.56939 -L 2.65024 -t 5500 -T 6500
rm -f "$HOME/.local/share/rofi/rofi_calc_history"
rm -f "$HOME/ly-session.log"
