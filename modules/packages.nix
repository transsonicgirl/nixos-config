# PACKAGES.NIX
# Package lists
{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
# Browsers / comms
        firefox
            google-chrome
            discord
            signal-desktop
            telegram-desktop
            thunderbird

# System utils
            nautilus

# Productivity / media
            obsidian
            libreoffice-still
            obs-studio
            spotify
            vlc
            krita
            gimp
            darktable
            calibre

# Terminals + shell tools
            kitty
            fish
            ripgrep
            fd
            bottom
            hyfetch
            wget
            rsync
            unzip
            unrar
            p7zip

# Hyprland/desktop
            waybar
            wofi
            hyprpaper
            grim
            slurp
            wl-clipboard
            playerctl
            bibata-cursors

# Secrets / VPN
            _1password-gui
            _1password-cli
            keepassxc
            mullvad-vpn
            tor-browser

# Games / launchers
            steam
            lutris
            prismlauncher
            protontricks

# Engineering
            freecad
            prusa-slicer
            openscad
            kicad
            ];

}
