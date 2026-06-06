{ lib, modulesPath, ... }:
# Starter hardware config for morpheus, derived from the Arch context dump.
#
# IMPORTANT: when you actually install NixOS, run `nixos-generate-config` on
# the new system and reconcile its output with this file. The UUIDs below
# match the current Arch install — if you re-partition or re-create the
# btrfs/LUKS volumes during the NixOS install, those UUIDs will change.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci_renesas" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4913665a-1e25-45ed-a551-1202a647d02a";
    fsType = "btrfs";
    options = [ "space_cache=v2" "compress=zstd" ];
  };

  # LUKS-on-LVM-less setup: encrypted root partition unlocked to /dev/mapper/root.
  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/dbdf8fd1-9658-45fe-a693-8ab92eb1e6c1";
    preLVM = true;
    allowDiscards = true;
  };

  fileSystems."/mnt/arch" = {
    device = "/dev/mapper/arch-root";
    fsType = "btrfs";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1B51-B190";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Bulk data btrfs disks. Mounting under /home/transsonicgirl matches the
  # existing Arch layout — adjust if you'd rather hang them off /mnt.
  fileSystems."/home/transsonicgirl/The-Box-3" = {
    device = "/dev/disk/by-uuid/648d72b8-12bc-4234-9b71-ebc6e6a2c612";
    fsType = "btrfs";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."/home/transsonicgirl/WOPR" = {
    device = "/dev/disk/by-uuid/55d34b42-da62-47f9-9892-e36451294d2c";
    fsType = "btrfs";
    options = [ "defaults" "nofail" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
