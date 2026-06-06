{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "trinity";

  # Laptop-flavored extras. CPU/GPU vendor not in the context dump — adjust
  # the videoDrivers list and hardware.graphics packages after install.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Power management for laptops.
  services.tlp.enable = true;
  services.thermald.enable = true;          # safe no-op on AMD
  powerManagement.enable = true;

  # Touchpad / brightness / mic / etc.
  services.libinput.enable = true;
  programs.light.enable = true;

  networking.networkmanager.enable = true;
}
