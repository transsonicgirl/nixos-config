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
        previewqt
        keymapp

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
        zoom-us

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
        kicad
    ];

# Program enables
    programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    services.mullvad-vpn.enable = true;
    hardware.openrazer.enable = true;
    hardware.openrazer.users = [ "transsonicgirl" ];
    services.tor.enable = true;
    services.tor.client.enable = true;
    services.tailscale.enable = true;
    programs.fish.enable = true;
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs._1password-gui.polkitPolicyOwners = [ "transsonicgirl" ];
}
