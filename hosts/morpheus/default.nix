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
        mesa
    ];
    extraPackages32 = with pkgs; [
        pkgsi686Linux.mesa
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Desktop-only services from the Arch dump.
  hardware.openrazer.enable = true;   # Razer mouse dock + polychromatic

  # MOZA R5 wheelbase.
  #
  # Forza Horizon 6 reads the accelerator from HID usage Y, but Wine's SDL
  # backend maps SDL axis *index* through a fixed usage table and the R5
  # interleaves dead axes among its live ones, so usage Y lands on a dead axis
  # and the game sees no usable wheel. This re-exposes it with the pedals on
  # the usages a driving game expects.
  #
  # Not enabled globally: set the game's Steam launch options to
  #   moza-fh6-wrap %command%
  # which runs the shim only for as long as the game does.
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/moza-fh6-shim { })
  ];

  # Wired NIC (Realtek r8169 enp8s0).
  networking.interfaces.enp8s0.useDHCP = true;

  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
}
