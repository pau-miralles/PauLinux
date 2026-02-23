{ config, pkgs, lib, ... }:

{
  home.username = "pau";
  home.homeDirectory = "/home/pau";
  home.stateVersion = "25.11"; # Keep this the same as your system version

  # This makes home-manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # GUI Apps
    audacity
    handbrake
    libreoffice-fresh
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
    udiskie # Automatic USB drives
    gammastep # Night Light
    pavucontrol # GUI Audio Panel
    wiremix # TUI Pipewire Audio Panel
    impala # TUI Wifi Panel
    bluetui # TUI Bluetooth Panel
    posy-cursors
    ffmpegthumbnailer # Video thumbnails
    libgsf # ODF (LibreOffice) thumbnails
    mpv
  ];

  services.cliphist.enable = true;
  services.udiskie.enable = true;
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 39.5; # Palma coordinates
    longitude = 2.6;
  };


  xdg.configFile = {
  "fastfetch".source = ./config/fastfetch;
  "sway".source = ./config/sway;
  "nvim".source = ./config/nvim;
  };

  programs.kitty = {
    enable = true;
  settings = {
      window_padding_width = 5;
      window_border_width = 2;
      background_opacity = lib.mkForce "0.8";
      cursor_trail = 1;
      cursor_trail_start_threshold = 0;
      confirm_os_window_close = 0;
  };
  keybindings = {
    "ctrl+tab" = "next_tab";
    "ctrl+1" = "goto_tab 1";
    "ctrl+2" = "goto_tab 2";
    "ctrl+3" = "goto_tab 3";
    "ctrl+4" = "goto_tab 4";
    "ctrl+5" = "goto_tab 5";
    "ctrl+6" = "goto_tab 6";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      q = "exit";
      ff = "fastfetch --logo small";
      ls = "eza --icons --hyperlink";
      ll = "eza -l --header --icons --hyperlink";
      la = "eza -a --icons --hyperlink";
      lt = "eza -T --level=2 --icons --hyperlink";
      v = "nvim";
      cat = "bat";
      sync = "cd ~/.nixos-config/ && nix flake update && sudo nixos-rebuild switch --flake .#framework && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5 && sudo nix-collect-garbage && sudo nixos-rebuild boot --flake .#framework && fwupdmgr refresh && fwupdmgr update";
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

  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "default";
      extensions.force = true;
      userChrome = builtins.readFile ./config/firefox/userChrome.css;
      userContent = builtins.readFile ./config/firefox/userContent.css;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "apz.overscroll.enabled" = false;
        "browser.gesture.swipe.left" = "";
        "browser.gesture.swipe.right" = "";
        "gfx.webrender.all" = true;
        "widget.wayland.opaque-region.enabled" = true;
        "full-screen-api.transition-duration.enter" = "0 0";
        "full-screen-api.transition-duration.leave" = "0 0";
        "full-screen-api.warning.delay" = 0;
        "full-screen-api.warning.timeout" = 0;
      };

      search = {
        force = true;
        default = "Brave";
        engines = {
          "Brave" = {
            urls = [{
              template = "https://search.brave.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];
          };
        };
      };
    };
  };
  stylix.targets.firefox = {
    profileNames = [ "default" ];
    colorTheme.enable = true; 
  };


  programs.rofi = {
    enable = true;
    package = pkgs.rofi; 

    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-emoji
    ];

    extraConfig = {
      modi = "drun,calc,window,emoji";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      display-drun = "   Apps ";
      display-calc = "   Calc ";
      display-window = " 󰕰  Window";
      display-emoji = "   Emoji ";
      # Enable the sidebar to switch modes with Shift+Left/Right
      sidebar-mode = true;
    };
  };


  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 20;
        modules-left = [ "battery" "power-profiles-daemon" "temperature" "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "network" "backlight" "pulseaudio" "clock" ];

        "sway/workspaces" = {
          all-outputs = true;
        };
        "sway/window" = {
          max-length = 50;
        };
        "battery" = {
          interval = 60;
          format = "{capacity}% ({time}) {icon}";
          format-charging = "{capacity}% ({time}) "; 
          format-icons = [ "" "" "" "" "" ];
        };
        "temperature" = {
          critical-threshold = 80;
          format-critical = "⚠{temperatureC}°C";
          format = "{temperatureC}°C";
        };
        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} 󰊗";
          tooltip-format = "{ifname} via {gwaddr} 󰊗";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          on-click = "~/.nixos-config/config/network.sh";
        };
        "backlight" = {
          format = "{percent}% {icon}";
          format-icons = ["" "" "" "󰖨" ""];
        };
        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "Muted ";
          format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" ""];
          };
          scroll-step = 1;
          on-click = "/etc/profiles/per-user/pau/bin/pavucontrol";
        };
        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "";
            performance = "";
            balanced = "";
            power-saver = "";
          };
        };
        "clock" = {
          interval = 1;
          format = "{:%H:%M:%S %d/%m/%y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: inherit;
        min-height: 0;
      }
      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: white;
        border-bottom: 3px solid transparent;
      }
      #workspaces button.focused {
        border-bottom: 3px solid white;
      }
      #battery,
      #clock,
      #workspaces,
      #mode,
      #window,
      #temperature,
      #network,
      #pulseaudio,
      #backlight,
      #power-profiles-daemon {
        padding: 0 10px;
      }
    '';
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "pau-miralles";
      email = "pmms0808@gmail.com";
    };
  };
}
