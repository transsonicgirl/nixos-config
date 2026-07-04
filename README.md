# nixos-config
A NixOS configuration flake for my various systems. 
## Layout

```
flake.nix                   # entry point, defines both nixosConfigurations
modules/
    auto-update.nix         # Auto-update config
    boot-grub.nix           # Grub & bootloader volume settings
    config.nix              # Overall Nix config & NixOS version
    desktop.nix             # Configuration for desktop & login managers
    dev.nix                 # Development packages & tools
    packages.nix            # Packages to install
    system.nix              # System-level config (persists across hosts)
hosts/
    morpheus/               # Morpheus-specific config
    trinity/                # Trinity-specific config
home/
    appconfig/              # Configs/fixes/wrappers for various applications
    assets/                 # Assets for different programs to use
    dotfiles/               # Config dotfiles for various programs
        hypr/               # hyprland dotfiles
        waybar/             # waybar dotfiles
    nvim/                   # Neovim preferences (also at github.com/transsonicgirl/nvim-config)
    transsonicgirl.nix      # home-manager for transsonicgirl
```

