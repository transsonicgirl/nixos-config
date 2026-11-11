#DESKTOP.NIX
#Desktop setup & config
{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Lock screen. The NixOS module (not just the package) matters: it creates
  # the `hyprlock` PAM service — without it hyprlock can't verify your password.
  programs.hyprlock.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
