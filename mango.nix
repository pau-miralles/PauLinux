{ pkgs, ... }:
{
  hardware.graphics.enable = true; # OpenGL (required for Wayland)
  programs.mango.enable = true;
  security.pam.services.waylock = {};
  environment.systemPackages = with pkgs; [
    libnotify     # To send notifications
    swaybg        # Wallpapers
    waylock       # Lockscreen
    wl-clipboard  # Clipboard manager backend
    grim          # Screenshot tool
    slurp         # Screen area selector
    polkit_gnome  # Authentication agent
    wlr-randr     # Rotate display
    brightnessctl # Brightness control
  ];
  fonts.packages = with pkgs; [ nerd-fonts.ubuntu-mono ];
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
