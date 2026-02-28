{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./sway.nix
    ];
  boot = { # Bootloader
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 0;
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      kernelModules = [ "amdgpu" ];
      systemd.enable = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
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
  networking.networkmanager.enable = true; # Enable networking
  networking.networkmanager.wifi.backend = "iwd";
  systemd.services.NetworkManager-wait-online.enable = false;

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8"; # Internationalisation properties
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
  services.xserver.xkb = { # Configure keymap in X11
    layout = "es";
    variant = "";
  };
  console.keyMap = "es";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs;[
      rocmPackages.clr.icd
    ];
  };
  zramSwap.enable = true;

  users.users.pau = { # Define a user account. Don't forget to set a password with ‘passwd’
    isNormalUser = true;
    description = "pau";
    extraGroups = [ "networkmanager" "wheel" "uinput" ];
    packages = with pkgs; [];
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ # Packages installed in system profile
    git
    vim
    wget
  ];
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable Flakes
  # List services that you want to enable:
  services.fwupd.enable = true; # Framework update
  services.openssh.enable = true; # Enable the OpenSSH daemon.
  nix.settings.auto-optimise-store = true; # Garbage collecting
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-generations +5";
  };
  security.rtkit.enable = true; # Sound (Pipeware)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.fprintd.enable = false; # No fingerprint
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];
  systemd.services.cups.wantedBy = lib.mkForce [ ];
  services.power-profiles-daemon.enable = true;

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
  services.udisks2.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

  services.kanata = {
    enable = true;
    keyboards.internal = {
      configFile = ./config/kanata/kanata.kbd;
      devices = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
    };
  };
  systemd.services.kanata-internal = {
    serviceConfig.Type = lib.mkForce "simple"; # Force it to be non-blocking
    wantedBy = lib.mkForce [ "multi-user.target" ];
    after = [ "local-fs.target" ]; # Start it slightly later to let the screen initialize first
    before = lib.mkForce [ ];
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      bigclock = true;
      blank_password = true;
    };
  };
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

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
      monospace.package = pkgs.nerd-fonts.ubuntu-mono;
      monospace.name = "UbuntuMono Nerd Font";
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = config.stylix.fonts.monospace;
    };
    cursor.package = pkgs.posy-cursors;
    cursor.name = "Posy_Cursor";
    cursor.size = 32;
    opacity.desktop = 0.8;
    opacity.popups = 0.8;
  };

  specialisation.light.configuration = {
    stylix.polarity = lib.mkForce "light";
  };
  security.sudo.extraRules = [
    {
      users = [ "pau" ];
      commands =[
        { command = "/run/current-system/specialisation/light/bin/switch-to-configuration"; options = [ "NOPASSWD" ]; }
        { command = "/nix/var/nix/profiles/system/bin/switch-to-configuration"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  networking.firewall.allowedTCPPorts = [ 22000 ]; # For Syncthing
  networking.firewall.allowedUDPPorts =[ 22000 21027 ];

  # This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions on your system were taken. It‘s perfectly fine and recommended to leave this value at the release version of the first install of this system.
  system.stateVersion = "25.11"; # DO NOT TOUCH
}
