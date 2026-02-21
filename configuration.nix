{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
./sway.nix
    ];

  # Bootloader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/vda";
  # boot.loader.grub.useOSProber = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "framework"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.iwd.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "es_ES.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "es";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pau = {
    isNormalUser = true;
    description = "pau";
    extraGroups = [ "networkmanager" "wheel" "uinput" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # --- SOUND (Pipewire) ---
  # Remove sound.enable or pulse.enable if they exist!
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # --- BLUETOOTH ---
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true; # GUI for managing bluetooth

  # --- PRINTING ---
  services.printing.enable = true;
  # specific drivers for most common printers
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];

  # Enable Power Profiles Daemon
  services.power-profiles-daemon.enable = true;


# --- STYLIX CONFIGURATION ---
  stylix = {
    enable = true;
    targets.gtk.enable = true;
    image = ./config/wallpaper.jpg;

    polarity = "dark";
    fonts = {
      sizes = {
        terminal = 18;
        applications = 12;
      };
      monospace = {
        package = pkgs.nerd-fonts.ubuntu-mono;
        name = "UbuntuMono Nerd Font";
      };
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = config.stylix.fonts.monospace;
    };
    cursor.package = pkgs.posy-cursors;
    cursor.name = "Posy_Cursor_125_175";
    cursor.size = 64;
    opacity = {
      desktop = 0.8;
      popups = 0.8;
    };
  };


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  programs.thunar = {
    enable = true;
    plugins = [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman
    ];
  };
  services.gvfs.enable = true;    # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
  programs.xfconf.enable = true;  # Required to save Thunar settings

  services.kanata = {
    enable = true;
    keyboards = {
      internal = {
        configFile = ./config/kanata/kanata.kbd; 
        # devices = [ "/dev/input/by-path/..." ]; 
      };
    };
  };


  environment.sessionVariables = {
    XCURSOR_THEME = "Posy_Cursor_125_175";
    XCURSOR_SIZE = "64";
  };
  environment.variables = {
    XCURSOR_THEME = "Posy_Cursor_125_175";
    XCURSOR_SIZE = "64";
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      bigclock = true;
      blank_password = true;
    };
  };

  services.displayManager.generic.environment = {
    XCURSOR_THEME = "Posy_Cursor_125_175";
    XCURSOR_SIZE = "64";
  };
}
