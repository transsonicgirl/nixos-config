# hardware-configuration.nix — morpheus, internal NVMe edition
#
# This REPLACES the USB-trial hardware-configuration.nix. It only describes the
# disk layout, LUKS unlock, and kernel modules for the real NVMe. Everything else
# in your morpheus config (amdgpu early-load, Renesas USB firmware, desktop.nix /
# Hyprland / SDDM, PipeWire, Mullvad, Tailscale, Fish, …) is unchanged and still
# imported exactly as before — none of it cares which disk root lives on.
#
# All UUIDs below are taken verbatim from your `lsblk -f` / `blkid` output.

{ config, lib, pkgs, modulesPath, ... }:

{
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
    
      # ---- Modules needed early: reach the NVMe, then unlock LUKS ----
      boot.initrd.availableKernelModules = [
        "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];
    
      # ---- Unlock the encrypted partition (nvme0n1p2) in the initrd ----
      # This UUID is the crypto_LUKS *container* from `blkid` — NOT the btrfs UUID.
      # Mapper name "cryptroot" is internal to NixOS and won't clash with Arch's "root".
      boot.initrd.luks.devices."cryptroot" = {
        device = "/dev/disk/by-uuid/dbdf8fd1-9658-45fe-a693-8ab92eb1e6c1";
        allowDiscards = true;   # lets periodic fstrim reach the SSD through LUKS
        keyFile = "/crypto_keyfile.bin";
      };

      boot.initrd.secrets = {
        "/crypto_keyfile.bin" = "/boot/crypto_keyfile.bin";
      };
    
      # ---- Filesystems ----
      # The three btrfs entries are all the SAME filesystem (UUID 0633f804…), the one
      # inside the unlocked LUKS volume. They differ ONLY by which subvolume they mount.
      # Arch keeps living on the top-level subvolume (subvolid 5); we never touch it.
    
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/0633f804-ae29-4cd1-b5f6-0542091783ec";
        fsType = "btrfs";
        options = [ "subvol=@nixos" "compress=zstd" "noatime" ];
      };
    
      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/0633f804-ae29-4cd1-b5f6-0542091783ec";
        fsType = "btrfs";
        options = [ "subvol=@nixos-home" "compress=zstd" "noatime" ];
      };
    
    
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

    fileSystems."/home/transsonicgirl/Unraid-Server/Vault" = {
        device = "//192.168.0.42/Vault";
        fsType = "cifs";
        options = [
        "credentials=/home/transsonicgirl/.smbcredentials"
        "file_mode=0777" "dir_mode=0777"
        "x-systemd.automount" "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"
        ];
    };

    fileSystems."/home/transsonicgirl/Unraid-Server/Caitlyn" = {
        device = "//192.168.0.42/Caitlyn";
        fsType = "cifs";
        options = [
        "credentials=/home/transsonicgirl/.smbcredentials"
        "file_mode=0777" "dir_mode=0777"
        "x-systemd.automount" "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"
        ];
    };

    fileSystems."/home/transsonicgirl/Unraid-Server/appdata" = {
        device = "//192.168.0.42/appdata";
        fsType = "cifs";
        options = [
        "credentials=/home/transsonicgirl/.smbcredentials"
        "file_mode=0777" "dir_mode=0777"
        "x-systemd.automount" "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"
        ];
    };

    # The unencrypted ESP (nvme0n1p1). Only GRUB's tiny EFI stub goes here.
    # Kernels + initrds live in /boot on the *encrypted* root, so 300M is plenty
    # and stays plenty no matter how many generations you keep.
    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/3FC5-9FB5";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
    };

    # Periodic TRIM — preferred over continuous discard for SSD health + safety.
    services.fstrim.enable = true;

    swapDevices = [ ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
}
