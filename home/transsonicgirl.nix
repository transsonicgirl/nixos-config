{ config, pkgs, ... }:
{
    home = {
        username = "transsonicgirl";
        homeDirectory = "/home/transsonicgirl";
        stateVersion = "26.05";
        pointerCursor = {
            name = "Catppuccin-Mocha-Dark-Cursors";
            package = pkgs.catppuccin-cursors.mochaDark;
            hyprcursor.enable = true;
            size = 24;
        };
        packages = with pkgs; [
            bibata-cursors
            hyfetch
            bpytop
        ];

    };
  
    programs.home-manager.enable = true;
  
    xdg.configFile."nvim" = {
      source = ./nvim;
      recursive = true;
    };
  
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
  
    xdg.configFile."hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${inputs.self}/home/dotfiles/hypr";
    xdg.configFile."waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${inputs.self}/home/dotfiles/waybar";
  
    programs.kitty.enable = true;
}
