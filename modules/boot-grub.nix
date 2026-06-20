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
        enableCryptodisk = false;
        device           = "nodev";
        useOSProber      = true;
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";
}
