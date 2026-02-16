{ config, pkgs, lib, ... }:

{
  home.username = "pau";
  home.homeDirectory = "/home/pau";
  home.stateVersion = "25.11"; # Keep this the same as your system version

  # This makes home-manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # GUI Apps
    firefox
    audacity
    thunar
    handbrake
    libreoffice-fresh
    kdePackages.kdenlive
    obs-studio
    obsidian
    gimp
    vlc
    syncthing
    
    # CLI Tools
    neovim
    yazi
    rmpc
    bottom
    fastfetch
    cava
    eza
    bat
    fzf
    ripgrep
    zoxide
    ffmpeg
    tty-clock
    tealdeer
    speedtest-cli
    python3
    
    cliphist # Clipboard backend
    posy-cursors
  ];


  xdg.configFile = {
  # "waybar".source = ./config/waybar;
  # "wofi".source = ./config/wofi;
  # "sway".source = ./config/sway;
  "nvim".source = ./config/nvim;
  # "yazi".source = ./config/yazi;
  };
  

  programs.kitty = {
    enable = true;
    
  settings = {
      hide_window_decorations = "yes";
      window_padding_width = 5;
      window_border_width = 2;
      background_opacity = lib.mkForce "0.65";
      dynamic_background_opacity = "yes";
      background_blur = 1;
      active_opacity = lib.mkForce "0.8";
      inactive_opacity = lib.mkForce "0.7";
      tab_title_template = "{title}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      cursor_trail = 1;
      cursor_trail_start_threshold = 0;
      close_on_child_death = "yes";
      allow_remote_control = "yes";
      confirm_os_window_close = 0;
  };

  keybindings = {
    "ctrl+tab"     = "next_tab";
    "ctrl+shift+tab" = "previous_tab";
    "ctrl+shift+n" = "new_os_window_with_cwd";
    
    "ctrl+1" = "goto_tab 1";
    "ctrl+2" = "goto_tab 2";
    "ctrl+3" = "goto_tab 3";
    "ctrl+4" = "goto_tab 4";
    "ctrl+5" = "goto_tab 5";
    "ctrl+6" = "goto_tab 6";
    "ctrl+7" = "goto_tab 7";
    "ctrl+8" = "goto_tab 8";
    "ctrl+9" = "goto_tab 9";
    "ctrl+0" = "goto_tab 10";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      q = "exit";
      c = "clear";
      ff = "fastfetch --logo small";
      ls = "eza --icons --hyperlink";
      ll = "eza -l --header --icons --hyperlink";
      la = "eza -a --icons --hyperlink";
      lt = "eza -T --level=2 --icons --hyperlink";
      v = "nvim";
      cat = "bat";
      f = "fzf";
      wttr = "curl wttr.in/Palma";
      clock = "tty-clock -c -C 7 -s -d 1000 -f '%A, %B %d, %Y' -b";
    };

    initExtra = ''
      export PS1="❭\w " # Custom Prompt
      
      # Environment Variables
      export VISUAL='nvim'
      export EDITOR='nvim'

      # Yazi Function (Shell Wrapper)
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
      
      # Cargo env (if you use rustup)
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi
    '';
  };

  # Enable Zoxide and FZF integration automatically for Bash
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  xdg.configFile."sway/config".text = ''
    # --- Variables ---
    set $mod Mod4
    set $term kitty
    set $menu wmenu-run

    # Direction keys
    set $left h
    set $down j
    set $up k
    set $right l

    # exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
    exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP

    # --- SwayFX Settings ---
    
    # 1. Window Blur
    blur enable
    blur_passes 2
    blur_radius 5
    blur_noise 0.01

    # 2. Transparency Rules
    # Base rule: Everything is translucent (0.85)
    for_window [app_id=".*"] opacity 0.85
    for_window [class=".*"] opacity 0.85
    
    # Exceptions: Production/Video apps stay 100% opaque
    for_window [app_id="firefox"] opacity 1
    for_window [app_id="vlc"] opacity 1
    for_window [app_id="org.kde.kdenlive"] opacity 1
    for_window [class="Gimp"] opacity 1
    for_window [app_id="gimp-2.10"] opacity 1
    # Image viewers usually look better opaque
    for_window [app_id="imv"] opacity 1

    # 3. Rounded Corners
    corner_radius 6

    # 4. Shadows
    shadows enable

    # 5. Gaps & Borders
    default_border pixel 1
    default_floating_border pixel 1
    gaps inner 10
    gaps outer 0
    smart_gaps off

    # 6. Layer Shell Effects
    layer_effects "wmenu" blur enable; layer_effects "wmenu" corner_radius 6
    layer_effects "panel" blur enable

    # --- Output & Input ---
    output * bg /etc/nixos/config/wallpaper.jpg fill

    input * {
      xkb_layout es
    }

    input type:touchpad {
      dwt enabled
      tap enabled
      natural_scroll enabled
      middle_emulation enabled
    }

    # --- Key bindings ---
    bindsym $mod+e exec thunar
    bindsym $mod+w exec firefox
    
    # -- Basics --
    bindsym $mod+Return exec $term
    bindsym $mod+Shift+q kill
    bindsym $mod+d exec $menu
    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
    
    # Custom
    bindsym $mod+v exec cliphist list | wofi --dmenu | cliphist decode | wl-copy
    bindsym $mod+Shift+f floating toggle
    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle

    # -- Navigation --
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # -- Moving Windows --
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # -- Workspaces --
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

    # -- Layout --
    bindsym $mod+t layout tabbed
    bindsym $mod+s layout toggle split
    bindsym $mod+f fullscreen
    bindsym $mod+a focus parent

    # -- Resize Mode --
    mode "resize" {
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px
        bindsym Left resize shrink width 10px
        bindsym Down resize grow height 10px
        bindsym Up resize shrink height 10px
        bindsym Right resize grow width 10px
        bindsym Return mode "default"
        bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"

    # -- Utilities --
    bindsym Print exec grim
    bindsym --locked XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
    bindsym --locked XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
    bindsym --locked XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
    bindsym --locked XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
    bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%-
    bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+

    # --- Services ---
    exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    exec_always autotiling

    exec swayidle -w \
         timeout 300 'swaylock -f -c 000000' \
         timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
         before-sleep 'swaylock -f -c 000000'

    # --- Status Bar ---
    bar {
      position bottom
      mode dock
      modifier none
      status_command while date +'%Y-%m-%d %X'; do sleep 1; done
    }
  '';


  # Configure some of the CLI tools to be "official" (This enables better integration like aliases)
  programs.git.enable = true;


  services.cliphist.enable = true;
}
