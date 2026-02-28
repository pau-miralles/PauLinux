{ config, pkgs, lib, ... }:
let
  rofi-power = pkgs.writeShellScriptBin "rofi-power" (builtins.readFile ./config/rofi-power.sh);
  rofi-wlsunset = pkgs.writeShellScriptBin "rofi-wlsunset" (builtins.readFile ./config/rofi-wlsunset.sh);
  toggle-theme = pkgs.writeShellScriptBin "toggle-theme" (builtins.readFile ./config/toggle-theme.sh);
in
{
  home.username = "pau";
  home.homeDirectory = "/home/pau";
  home.stateVersion = "25.11"; # Keep this the same as your system version
  programs.home-manager.enable = true; # This makes home-manager manage itself
  home.packages = with pkgs; [
    syncthing
    obsidian
    libreoffice-fresh
    libgsf # ODF (LibreOffice) thumbnails
    gimp
    audacity
    vlc
    handbrake
    obs-studio

    python3
    ffmpeg
    yazi
    eza
    fzf
    bat
    ripgrep
    zoxide
    tealdeer
    rmpc
    cava
    bottom
    fastfetch
    tty-clock
    speedtest-cli

    cliphist
    wlsunset
    udiskie # Automatic USB drives
    playerctl # Play/Pause buttons
    pavucontrol # GUI Audio Panel
    wiremix # TUI Audio Panel
    impala # TUI Wifi Panel
    bluetui # TUI Bluetooth Panel
    ffmpegthumbnailer # Video thumbnails
    jq # Json, for the sway tabs script
    nodejs # For markdown-preview.nvim
    posy-cursors

    gcc
    pyright
    nixd
    clang-tools # C/C++ (includes clangd)
    vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    typescript-language-server
    arduino-language-server

    toggle-theme
    rofi-power
    rofi-wlsunset
    rofi-emoji
  ];

  services.cliphist = {
    enable = true;
    allowImages = true;
  };
  services.udiskie.enable = true;
  services.mpd = {
    enable = true;
    musicDirectory = "/home/pau/Music";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PulseAudio"
      }
    '';
    network.listenAddress = "any";
  };

  xdg.configFile = {
    "fastfetch".source = ./config/fastfetch;
    "sway".source = ./config/sway;
    # "yazi".source = ./config/yazi;
    "rmpc/config.ron".source = ./config/rmpc/config.ron;
    "rmpc/theme.ron".text = import ./config/rmpc/theme.nix { inherit config; };
  };

  programs.kitty = {
    enable = true;
    settings = {
      window_padding_width = 3;
      window_border_width = 0;
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

  programs.neovim = {
    enable = true;
    initLua = builtins.readFile ./config/nvim/init.lua;
  };
  stylix.targets.neovim = {
    enable = true;
    colors.enable = true;
    transparentBackground.main = true;
    transparentBackground.signColumn = true;
    transparentBackground.numberLine = true;
    plugin = "mini.base16";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      q = "exit";
      ls = "eza --icons --hyperlink";
      ll = "eza -l --header --icons --hyperlink";
      la = "eza -a --icons --hyperlink";
      lt = "eza -T --level=2 --icons --hyperlink";
      ltt = "eza -T --icons --hyperlink";
      cat = "bat";
      v = "nvim";
      f = "fzf";
      bluetooth = "sudo systemctl start bluetooth";
      printer = "sudo systemctl start cups";
      ff = "fastfetch --logo small";
      clock = "tty-clock -c -C 7 -s -d 1000 -f '%A, %B %d, %Y' -b";
      sync = "cd ~/.nixos-config/ && nix flake update && sudo nixos-rebuild switch --flake .#framework && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5 && sudo nix-collect-garbage && sudo nixos-rebuild boot --flake .#framework && fwupdmgr refresh && fwupdmgr update";
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
    '';
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      autoload
      mpv-gallery-view
      thumbfast
    ];
    config = {
      gpu-context = "wayland";
      hwdec = "auto-safe";
      vo = "gpu";
      prefetch-playlist-index = "yes";
      sws-scaler = "fast-bilinear";
      video-sync = "display-resample";
      image-display-duration = "inf";
      # loop-file = "inf";
      osd-bar = "no";
    };
    bindings = {
      "l" = "seek 5";
      "h" = "seek -5";
      "." = "add volume 2";
      "," = "add volume -2";
      "j" = "playlist-prev";
      "k" = "playlist-next";
      "f" = "cycle fullscreen";
      "q" = "quit";
      "g" = "script-binding playlist-view-toggle";
      "+" = "add video-zoom 0.1";
      "-" = "add video-zoom -0.1";
      "=" = "set video-zoom 0; set video-pan-x 0; set video-pan-y 0";
      "Ctrl+h" = "add video-pan-x 0.05";
      "Ctrl+l" = "add video-pan-x -0.05";
      "Ctrl+k" = "add video-pan-y 0.05";
      "Ctrl+j" = "add video-pan-y -0.05";
    };
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
        "media.rdd-ffmpeg.enabled" = true;
        "widget.wayland.fractional-scale.enabled" = true; # Crisper Wayland scaling
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
    plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ];
    extraConfig = {
      modi = "drun,calc";
      show-icons = true;
      display-drun = " ";
      display-calc = " ";
      sidebar-mode = false;
      kb-mode-next = "Shift+Right";
      kb-mode-previous = "Shift+Left";
      dpi = 192;
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
        modules-left = [ "battery" "power-profiles-daemon" "temperature" ];
        modules-center = [ "sway/workspaces" ];
        modules-right = [ "network" "backlight" "pulseaudio" "clock" ];
        "sway/workspaces" = {
          all-outputs = true;
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
          format-ethernet = "󰈀";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected ⚠";
        };
        "backlight" = {
          format = "{percent}% {icon}";
          format-icons = ["" "󰖨" "" ""];
        };
        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = " ";
          format-icons = {
              headphone = "";
              default = ["" ""];
          };
          scroll-step = 1;
          on-click = "/etc/profiles/per-user/pau/bin/pavucontrol";
        };
        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "{profile}";
          tooltip = true;
          format-icons = {
            default = "";
            performance = "";
            balanced = "";
            power-saver = "󰌪";
          };
        };
        "clock" = {
          interval = 1;
          format = "{:%d/%m/%y %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#f2c6a0'><b>{}</b></span>";
              days = "<span color='#e6b3c2'><b>{}</b></span>";
              weeks = "<span color='#d8a657'><b>W{}</b></span>";
              weekdays = "<span color='#eebd7a'><b>{}</b></span>";
              today = "<span color='#d3869b'><b><u>{}</u></b></span>";
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
        padding: 0 3px;
      }
      #battery,
      #clock,
      #workspaces,
      #mode,
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
