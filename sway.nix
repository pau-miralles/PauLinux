{ config, pkgs, ... }:

{
  # Enable OpenGL (required for Wayland)
  # Note: On older NixOS versions this was called hardware.opengl
  hardware.graphics.enable = true;

  # Enable the login manager (SDDM)
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Enable Sway
  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # Use SwayFX instead of standard Sway
    wrapperFeatures.gtk = true; # Fixes GTK apps in Sway
  };

  # Essential packages for the GUI
  environment.systemPackages = with pkgs; [
    waybar       # Status bar
    wofi         # App launcher (like Start menu)
    kitty        # Terminal Emulator
    mako         # Notification daemon
    libnotify    # To send notifications
    swaybg       # Wallpapers in Sway
    wl-clipboard # Clipboard manager backend
    grim         # Screenshot tool
    slurp        # Screen area selector
    autotiling   # Autotiling for Sway yessss
    polkit_gnome # Authentication agent
  ];

  # Install the Ubuntu Mono Nerd Font
  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
  ];

  # XDG Portals (Crucial for file dialogs and screen sharing)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  
  # Security (needed for some GUI apps to ask for passwords)
  security.polkit.enable = true;
}
