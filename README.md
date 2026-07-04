# nixos-config
A NixOS configuration flake for my various systems. 
## Layout

```
flake.nix                   # entry point, defines both nixosConfigurations

docs/                       # Documentation of various fixes/changes. Mostly claude-generated, take with a grain of salt.
    assetto-corsa-linux.md  # More detailed docs of AC setup drama. 

home/                       # Home-manager config
    appconfig/              # Configs/fixes/wrappers for various applications
    assets/                 # Assets for different programs to use
    dotfiles/               # Config dotfiles for various programs
        hypr/               # hyprland dotfiles
            Wallpapers/     # Wallpaper images
        waybar/             # waybar dotfiles
    nvim/                   # Neovim preferences (also at github.com/transsonicgirl/nvim-config)
    transsonicgirl.nix      # home-manager for transsonicgirl

hosts/
    morpheus/               # Morpheus-specific config
    trinity/                # Trinity-specific config

modules/
    auto-update.nix         # Auto-update config
    boot-grub.nix           # Grub & bootloader volume settings
    config.nix              # Overall Nix config & NixOS version
    desktop.nix             # Configuration for desktop & login managers
    dev.nix                 # Development packages & tools
    packages.nix            # Packages to install
    system.nix              # System-level config (persists across hosts)

pkgs/                       # Folder for custom packages as needed.
```
## SSH/auth
Quite obviously my ssh pubkey will not work for you if you want to SSH into your system. If you're installing with this flake you should fork & substitute that for your own. 

## On wallpapers
Note that all images in the wallpapers/ dir are either my own photography or NASA public domain imagery. This gives me the right to redistribute them under the GPL license. If you fork this & put copyrighted imagery in that dir for your own system, you'll technically be violating copyright law. My redistribution of these images implies neither ownership nor endorsement by the creator(s) (outside of my own photography). 

## Special config notes
### Proton
At time of writing (4 Jul 2026) Nixpkgs' automatic GE proton linking is broken. You can see a symlink workaround to this in transsonicgirl.nix. 
### Assetto Corsa
This game is a nightmare to get running with content manager under Linux. Here's some notes on how I got this working. 
- Only works on proton 9.0-4. GE proton breaks CSP linking under my system's config. 
- Launch options should be set to `PROTON_ENABLE_WAYLAND=0 WINEDLLOVERRIDES="dwrite=n,b" %command%`.
- Window rule needed to be set under hyprland since AC doesn't like to fullscreen itself properly otherwise. Make sure you set Assetto Corsa to windowed borderless mode under content manager & let hyprland fullscreen it automatically. 
- You will need to have proper fonts installed. Most of these can be taken care of with protontricks `allfonts` but Segoe UI is a notable exception & gets automatically installed under home-manager in this config. 
- See [docs/assetto-corsa-linux.md] for more information.
### Packages
I've run into a few packages that I like that aren't in nixpkgs. I'll probably submit these to nixpkgs eventually, but for now they live in the pkgs dir here. 
- bpytop
    - Really nice-looking TUI system monitor. 
### Appconfig shells
Some apps don't like to play nice with Nix's layout, especially Steam games with native linux builds. I've put shells for them under `home/appconfig/` so they'll get fixed. 
- Kerbal Space Program
    - Expects dirs to be in places they won't be on Nix, so the shell constructed here makes sure it has the environment it wants. Note this doesn't apply unless you set it in the Steam launch options `ksp-wrapper %command%`. This isn't needed if you run it under Proton for mod compatibility. 

