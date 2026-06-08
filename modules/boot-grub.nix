{ config, lib, pkgs, ... }:
# GRUB configured so it does NOT clobber existing EFI entries (Arch, Windows).
#
# How this avoids clobbering:
#   - efiInstallAsRemovable = false  -> never overwrite /EFI/BOOT/BOOTX64.EFI
#   - canTouchEfiVariables = true    -> add a new "NixOS" efibootmgr entry
#                                       alongside (not replacing) Arch/Windows
#   - efiBootloaderId = "NixOS"      -> install to /boot/EFI/NixOS/ rather than
#                                       the default /EFI/GRUB (which could
#                                       collide with another distro's GRUB)
#   - useOSProber = true             -> detect Windows + Arch and add menu
#                                       entries so NixOS's GRUB can chainload
#                                       them
#
# Note: the existing Arch /boot is ~300MB and already 27% full. If you mount
# the same ESP at /boot here, watch free space — consider trimming old
# generations aggressively (the nix.gc settings in common.nix help).
{
    boot.loader.grub = {
        enable           = true;
        efiSupport       = true;
        enableCryptodisk = true;
        device           = "nodev";
        useOSProber      = false;     # stops the sdg1 noise; Windows can be a manual entry later
        extraEntries = ''
        menuentry "Arch Linux" {
            insmod part_gpt
            insmod fat
            search --no-floppy --fs-uuid --set=root 3FC5-9FB5
            linux /vmlinuz-linux root=UUID=0633f804-ae29-4cd1-b5f6-0542091783ec rw root=/dev/mapper/root rw
            initrd /initramfs-linux.img
        }
        '';
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";
}
