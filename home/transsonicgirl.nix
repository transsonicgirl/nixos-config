{ config, pkgs, ... }:
{
  home.username = "transsonicgirl";
  home.homeDirectory = "/home/transsonicgirl";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.pointerCursor = { 
    name = "Catppuccin-Mocha-Dark-Cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    hyprcursor.enable = true;
    size = 24;
  };

  # Preserve the existing Neovim config wholesale. The whole ./nvim tree is
  # copied into ~/.config/nvim; lazy.nvim will manage plugins on first run.
  # Re-deploying via `nixos-rebuild` will resync any local edits made here.
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Neovim itself is installed system-wide in modules/dev.nix; nothing more
  # needed here. If you want a hermetic, Nix-managed nvim instead, swap in
  # `programs.neovim.enable = true;` and start porting plugins to Nix.

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_add_path /opt/riscv/bin
    '';
  };

  programs.git = {
    enable = true;
    settings.user.name  = "Allison Byrnes";
    settings.user.email = "allison.byrnes42@gmail.com";
  };

  home.packages = with pkgs; [
    bibata-cursors
  ];

  # Live-editable (symlink to repo file, edit + hyprctl reload works):
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/nixos-config/home/dotfiles/hypr";
  xdg.configFile."waybar".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/nixos-config/home/dotfiles/waybar";

  programs.kitty.enable = true;
}
