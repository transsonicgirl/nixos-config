{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "morpheus";

  # AMD GPU (Radeon RX 7800 XT + iGPU on Granite Ridge).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ 
        rocmPackages.clr.icd 
        mesa.drivers
    ];
    extraPackages32 = with pkgs; [
        pkgsi686Linux.mesa.drivers
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Desktop-only services from the Arch dump.
  hardware.openrazer.enable = true;   # Razer mouse dock + polychromatic

  # Wired NIC (Realtek r8169 enp8s0).
  networking.interfaces.enp8s0.useDHCP = true;

  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
}
