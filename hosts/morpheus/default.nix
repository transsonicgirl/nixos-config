{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "morpheus";

  # AMD GPU (Radeon RX 7800 XT + iGPU on Granite Ridge).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ amdvlk rocmPackages.clr.icd ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ amdvlk ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Desktop-only services from the Arch dump.
  services.fancontrol.enable = false; # enable once fancontrol.conf is in place
  hardware.openrazer.enable = true;   # Razer mouse dock + polychromatic

  # Wired NIC (Realtek r8169 enp8s0).
  networking.interfaces.enp8s0.useDHCP = true;
}
