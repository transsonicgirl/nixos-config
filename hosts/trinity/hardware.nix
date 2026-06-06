{ lib, modulesPath, ... }:
# Placeholder hardware config for trinity (laptop).
#
# The context dump only covered morpheus, so this file is a stub. On a fresh
# NixOS install on trinity:
#   1. Run `nixos-generate-config --root /mnt`
#   2. Copy the generated /mnt/etc/nixos/hardware-configuration.nix into here,
#      replacing everything below the imports line.
#   3. Add any laptop-specific filesystems (e.g. LUKS device UUIDs).
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # --- REPLACE THESE STUBS AFTER nixos-generate-config ---
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
  # -------------------------------------------------------

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
