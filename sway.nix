{ config, pkgs, ... }:
{
  # OpenGL (required for Wayland)
  hardware.graphics.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # Use SwayFX instead of standard Sway
    wrapperFeatures.gtk = true; # Fixes GTK apps in Sway
  };

  environment.systemPackages = with pkgs; [
    waybar       # Status bar
    wofi         # App launcher
    kitty        # Terminal
    mako         # Notification daemon
    libnotify    # To send notifications
    swaybg       # Wallpapers in Sway
    wl-clipboard # Clipboard manager backend
    grim         # Screenshot tool
    slurp        # Screen area selector
    autotiling   # Autotiling for Sway yessss
    polkit_gnome # Authentication agent
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  security.polkit.enable = true;
}
