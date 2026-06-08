# nixos-config
A NixOS configuration flake for my various systems. 
## Layout

```
flake.nix                # entry point, defines both nixosConfigurations
modules/
    boot-grub.nix        # Grub & bootloader volume settings
    config.nix           # Overall Nix config & NixOS version
    desktop.nix          # Configuration for desktop & login managers
    dev.nix              # Development packages & tools
    packages.nix         # Packages to install
    system.nix           # System-level config (persists across hosts)
hosts/
  morpheus/              # Morpheus-specific config
  trinity/               # Trinity-specific config
home/
  transsonicgirl.nix     # home-manager for transsonicgirl
  nvim/                  # Neovim preferences (also at github.com/transsonicgirl/nvim-config)
```
