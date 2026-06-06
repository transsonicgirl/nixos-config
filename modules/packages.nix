{ pkgs, ... }:
{
  # User-facing applications. Curated from the Arch pacman list — not
  # exhaustive. Add what you actually use; trim what you don't.
  environment.systemPackages = with pkgs; [
    # Browsers / comms
    firefox
    google-chrome
    discord
    signal-desktop
    telegram-desktop
    nheko
    thunderbird

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
    neofetch
    wget
    rsync
    unzip
    unrar
    p7zip

    # Hyprland ecosystem
    waybar
    wofi
    hyprpaper
    grim
    slurp
    wl-clipboard
    playerctl

    # Secrets / VPN
    _1password-gui
    _1password-cli
    keepassxc
    mullvad-vpn
    tor-browser-bundle-bin

    # Games / launchers
    steam
    lutris
    prismlauncher

    # 3D / EE / CAD (subset — kicad is large; trim if you don't need it)
    freecad
    prusa-slicer
    openscad
    kicad
  ];

  programs.steam.enable = true;
  services.mullvad-vpn.enable = true;
}
