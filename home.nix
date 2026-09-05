{ config, pkgs, lib, ... }:
let
  rofi-power = pkgs.writeShellScriptBin "rofi-power" (builtins.readFile ./config/rofi-power.sh);
  rofi-wlsunset = pkgs.writeShellScriptBin "rofi-wlsunset" (builtins.readFile ./config/rofi-wlsunset.sh);
  toggle-theme = pkgs.writeShellScriptBin "toggle-theme" (builtins.readFile ./config/toggle-theme.sh);
  low-battery-warning = pkgs.writeShellScriptBin "low-battery-warning" (builtins.readFile ./config/low-battery-warning.sh);
  colors = config.lib.stylix.colors.withHashtag;
in
{
  home.username = "pau";
  home.homeDirectory = "/home/pau";
  home.stateVersion = "25.11"; # Keep this the same as your system version
  programs.home-manager.enable = true; # This makes home-manager manage itself
  home.sessionVariables = {
    GTK_IM_MODULE = "simple";
    NIXOS_OZONE_WL = "1";
  };
  home.packages = with pkgs; [
    obsidian
    libreoffice
    libgsf # ODF (LibreOffice) thumbnails
    gimp
    audacity
    vlc
    handbrake
    obs-studio
    mixxx
    # arduino-ide

    framework-tool-tui
    yazi
    tmuxp
    python3
    ffmpeg
    yt-dlp
    eza
    bat
    ripgrep
    tealdeer
    rmpc
    cava
    bottom
    fastfetch
    tty-clock
    live-server
    speedtest-cli

    wlsunset
    playerctl # Play/Pause buttons
    pavucontrol # GUI Audio Panel
    wiremix # TUI Audio Panel
    impala # TUI Wifi Panel
    bluetui # TUI Bluetooth Panel
    ffmpegthumbnailer # Video thumbnails
    jq # Json, for the sway tabs script
    nodejs # For markdown-preview.nvim
    yarn
    zip
    unzip

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
    libnotify
    low-battery-warning
  ];
  services.mako.enable = true; # Notification daemon
  services.syncthing.enable = true;
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
  services.udiskie.enable = true; # Automatic mount USB drives
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PulseAudio"
      }
    '';
    network.listenAddress = "any";
  };
  services.mpd-mpris.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "image/jpeg" = [ "mpv.desktop" ];
      "image/png" = [ "mpv.desktop" ];
      "image/gif" = [ "mpv.desktop" ];
      "image/webp" = [ "mpv.desktop" ];
      "image/svg+xml" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
    };
  };

  xdg.configFile = {
    "fastfetch".source = ./config/fastfetch;
    "sway".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos-config/config/sway";
    "tmuxp".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos-config/config/tmuxp";
    "rmpc/config.ron".source = ./config/rmpc/config.ron;
    "rmpc/theme.ron".text = import ./config/rmpc/theme.nix { inherit config; };
    "sway-colors".text = ''
      set $base00 ${colors.base00}
      set $base01 ${colors.base01}
      set $base02 ${colors.base02}
      set $base03 ${colors.base03}
      set $base04 ${colors.base04}
      set $base05 ${colors.base05}
      set $base06 ${colors.base06}
      set $base07 ${colors.base07}
      set $base08 ${colors.base08}
      set $base09 ${colors.base09}
      set $base0A ${colors.base0A}
      set $base0B ${colors.base0B}
      set $base0C ${colors.base0C}
      set $base0D ${colors.base0D}
      set $base0E ${colors.base0E}
      set $base0F ${colors.base0F}
    '';
  };

  programs.ghostty = {
    enable = true;
    settings = {
      background-opacity = 0.7;
      confirm-close-surface = false;
      custom-shader = "/home/pau/.nixos-config/config/cursor_tail.glsl";
      resize-overlay = "never";
      window-padding-balance = true;
      window-padding-color = "extend";
      scrollbar = "never";
      bell-features = false;
      app-notifications = false;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;
      mouse-hide-while-typing = true;
      scrollback-limit = 10000;
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    mouse = true;
    escapeTime = 0;
    baseIndex = 1;
    keyMode = "vi";
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins;[
      vim-tmux-navigator
      yank
      open
    ];
    extraConfig = ''
      set -ga terminal-overrides ",*:RGB"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[2 q'
      set -g set-clipboard on
      set -g focus-events on
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Tmux config reloaded"
      bind C-l send-keys 'C-l'
      bind - display-popup -E -w 75% -h 75% "tmux new-session -A -s scratchpad"
      bind -n M-f resize-pane -Z
      bind -n M-C-h previous-window
      bind -n M-C-l next-window

      # Status Bar (vim-tpipeline)
      set -g status-style "bg=default,fg=#${config.lib.stylix.colors.base05}"
      set -g status-justify absolute-centre
      set -g status-left-length 99
      set -g status-right-length 99
      set -g status-left ""
      set -g status-right ""

      # Stylix styling
      set -g window-status-style "fg=#${config.lib.stylix.colors.base09}"
      set -g window-status-format "#W"
      set -g window-status-current-style "bg=default,fg=#${config.lib.stylix.colors.base03},bold"
      set -g window-status-current-format "#W"

      # Windows
      bind c new-window -c "#{pane_current_path}"
      set -g renumber-windows on
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1

      # Split Windows (Vim Style)
      unbind '"'
      unbind %
      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"

      # Panes
      bind -r H swap-pane -U
      bind -r L swap-pane -D
      bind -r Left  resize-pane -L 5
      bind -r Down  resize-pane -D 5
      bind -r Up    resize-pane -U 5
      bind -r Right resize-pane -R 5

      # Alt+number to select window
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6

      # Vim-like Copy
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      unbind -T copy-mode-vi MouseDragEnd1Pane
    '';
  };

  programs.neovim = {
    withRuby = false;
    withPython3 = false;
    enable = true;
    plugins = with pkgs.vimPlugins;[
      nvim-treesitter.withAllGrammars
    ];
    initLua = ''
      dofile("${config.home.homeDirectory}/.nixos-config/config/nvim/init.lua")
    '';
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
      printer = "sudo systemctl start cups";
      ff = "fastfetch --logo small";
      clock = "tty-clock -c -C 7 -s -d 1000 -f '%A, %B %d, %Y' -b";
      sync = "cd ~/.nixos-config/ && sudo nixos-rebuild list-generations --flake .#framework && sudo nix-collect-garbage -d && sudo nixos-rebuild switch --flake .#framework && fwupdmgr refresh && fwupdmgr update";
      btm = "btm --battery";
      tf = "tmuxp freeze";
    };
    initExtra = ''
      export PS1="❭\w " # Custom Prompt
      # Environment Variables
      export VISUAL='nvim'
      export EDITOR='nvim'
      # Tmux function:
      tm() {
        if [ -z "$1" ]; then
          tmux ls 3>/dev/null | bat --style=plain --language=TOML
          echo .
          eza -T $HOME/.nixos-config/config/tmuxp/ | tail -n +2
        else
          if tmuxp load "$1" --check 2>/dev/null || [ -f "$HOME/.nixos-config/config/tmuxp/$1.yaml" ]; then
            tmuxp load "$1" -y
          else
            tmux new -A -s "$1"
          fi
        fi
      }
      # Tmuxp freeze:
      tmf() { tmuxp freeze "$1" -o ~/.config/tmuxp/"$1".yaml; }
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
      mpris
    ];
    config = {
      gpu-context = "wayland";
      hwdec = "auto-safe";
      vo = "gpu";
      prefetch-playlist-index = "yes";
      sws-scaler = "fast-bilinear";
      video-sync = "display-resample";
      image-display-duration = "inf";
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
    configPath = ".mozilla/firefox";
    enable = true;
    profiles.default = {
      id = 0;
      name = "default";
      extensions.force = true;
      userChrome = builtins.readFile ./config/firefox/userChrome.css;
      userContent = builtins.readFile ./config/firefox/userContent.css;
      extraConfig = ''
        ${builtins.readFile ./config/firefox/betterfox.js}
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("media.rdd-ffmpeg.enabled", true);
        user_pref("widget.wayland.fractional-scale.enabled", true);
        user_pref("browser.tabs.drawInTitlebar", true);
        user_pref("browser.compactmode.show", true);
        user_pref("browser.uidensity", 1);
        user_pref("apz.overscroll.enabled", false);
        user_pref("browser.gesture.swipe.left", "");
        user_pref("browser.gesture.swipe.right", "");
        user_pref("gfx.webrender.all", true);
        user_pref("full-screen-api.transition-duration.enter", "0 0");
        user_pref("full-screen-api.transition-duration.leave", "0 0");
        user_pref("full-screen-api.warning.delay", 0);
        user_pref("full-screen-api.warning.timeout", 0);
      '';
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
    theme = {
      "listview" = {
        lines = 12;
        columns = 1;
        fixed-height = false;
      };
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 18;
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
          on-click = "/etc/profiles/per-user/pau/bin/ghostty -e /etc/profiles/per-user/pau/bin/btm --battery";
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
          on-click = "/etc/profiles/per-user/pau/bin/ghostty -e /etc/profiles/per-user/pau/bin/impala";
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
