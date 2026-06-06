# nixos-config

Flake-based NixOS configuration for **morpheus** (desktop) and **trinity** (laptop).

## Layout

```
flake.nix                # entry point, defines both nixosConfigurations
modules/
  common.nix             # nix settings, user, locale, time, networkmanager, ssh, tailscale
  boot-grub.nix          # GRUB tuned to coexist with Arch + Windows entries
  desktop.nix            # Hyprland + SDDM + PipeWire + fonts + Bluetooth
  packages.nix           # GUI apps (browsers, comms, media, games, etc.)
  dev.nix                # toolchains, editors, embedded tooling
hosts/
  morpheus/              # AMD desktop, LUKS+btrfs, RX 7800 XT
  trinity/               # laptop — hardware stub, fill in after install
home/
  transsonicgirl.nix     # home-manager: shell, git, nvim deploy
  nvim/                  # your existing nvim config, copied verbatim
```

## Build / switch

```
sudo nixos-rebuild switch --flake .#morpheus
sudo nixos-rebuild switch --flake .#trinity
```

## GRUB / multi-boot notes

The bootloader module installs NixOS's GRUB at `/boot/EFI/NixOS/` with a
distinct efibootmgr entry named **NixOS**. It does **not**:

- overwrite `/EFI/BOOT/BOOTX64.EFI` (`efiInstallAsRemovable = false`)
- replace the existing Arch or Windows EFI variables

`useOSProber = true` so NixOS's GRUB menu picks up Arch + Windows
automatically. Your current ESP is only 300 MB and already ~27% full — keep
an eye on it and prune NixOS generations aggressively
(`configurationLimit = 10` in `boot-grub.nix` and weekly `nix.gc`).

## Before first install on trinity

`hosts/trinity/hardware.nix` is a stub. After booting the installer:

```
nixos-generate-config --root /mnt
# copy the generated hardware-configuration.nix into hosts/trinity/hardware.nix
```

## Neovim

Your existing `~/.config/nvim` is bundled under `home/nvim/` and deployed by
home-manager. lazy.nvim manages plugins at runtime; the lock file travels
with the repo so both hosts converge on the same plugin versions.
