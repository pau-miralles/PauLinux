{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
./sway.nix
    ];

  boot = {
    # Bootloader
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 0;
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      kernelModules = [ "amdgpu" ];
      systemd.enable = true;
    };
    kernelParams = [
    "quiet"                       # Reduces kernel output
    "loglevel=3"                  # Only show Errors (ignores warnings/info)
    "systemd.show_status=auto"    # ONLY show systemd status if a service fails or is slow
    "rd.systemd.show_status=auto" # Same as above, but for the very start (initrd)
    "rd.udev.log_level=3"         # Keep udev quiet unless it breaks
    "udev.log_priority=3"
    "8250.nr_uarts=0"             # Fixes the 3s serial port timeout
    "tpm_tis.interrupts=0"        # Fixes TPM wait
    "tpm.tpm_do_selftest=0"       # Skips TPM test
    "amdgpu.fastboot=1"           # Skips flicker/logo transitions
    "fbcon=nodefer"               # Tells the kernel to take the screen immediately
    ];
    blacklistedKernelModules = [
      "sp5100_tco"
      "8250_pnp"
    ];
  };

  systemd.targets.emergency.enable = false;

  systemd.services."home-manager-pau" = {
    before = lib.mkForce [ ]; # Don't block other services
    wantedBy = lib.mkForce [ "multi-user.target" ];
  };

  networking.hostName = "framework"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.iwd.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  systemd.services.NetworkManager-wait-online.enable = false;

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

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-generations +5";
  };

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

  services.fprintd.enable = false;
  # --- BLUETOOTH ---
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];
  # services.blueman.enable = true; # GUI for managing bluetooth

  # --- PRINTING ---
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];
  systemd.services.cups.wantedBy = lib.mkForce [ ];

  # Enable Power Profiles Daemon
  services.power-profiles-daemon.enable = true;

  services.logind.powerKey = "ignore";

# --- STYLIX CONFIGURATION ---
  stylix = {
    enable = true;
    targets.gtk.enable = true;
    image = ./config/wallpaper.jpg;
    # base16Scheme = ./config/themes/theme.yaml;

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
    cursor.name = "Posy_Cursor";
    cursor.size = 32;
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
    keyboards.internal = {
      configFile = ./config/kanata/kanata.kbd;
      devices = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
    };
  };
  
systemd.services.kanata-internal = {
    # Force it to be non-blocking
    serviceConfig.Type = lib.mkForce "simple"; 
    wantedBy = lib.mkForce [ "multi-user.target" ];
    # Optional: Start it slightly later to let the screen initialize first
    after = [ "local-fs.target" ];
    before = lib.mkForce [ ]; 
  };


  services.displayManager.ly = {
    enable = true;
    settings = {
      bigclock = true;
      blank_password = true;
      save_session = false;
    };
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
