swaybg -c "$(cat "$HOME/.config/base00")" &
waybar &
low-battery-warning &
systemd-run --user --unit=wlsunset-auto --collect wlsunset -l 39.56939 -L 2.65024 -t 5500 -T 6500
rm -f "$HOME/.local/share/rofi/rofi_calc_history"
rm -f "$HOME/ly-session.log"
