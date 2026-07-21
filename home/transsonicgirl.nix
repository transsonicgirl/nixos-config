{ inputs, config, pkgs, lib, ... }:
let
     fontsDir = ./assets/fonts;
     acFontsDir = "$HOME/WOPR/SteamLibrary/steamapps/compatdata/244210/pfx/drive_c/windows/Fonts/";
in
{
    imports = [
        ./appconfig/ksp.nix
    ];
    home = {
        username = "transsonicgirl";
        homeDirectory = "/home/transsonicgirl";
        stateVersion = "26.05";
        pointerCursor = {
            enable = true;
            name = "Catppuccin-Mocha-Dark-Cursors";
            package = pkgs.catppuccin-cursors.mochaDark;
            hyprcursor.enable = true;
            size = 24;
        };
        packages = with pkgs; [
            bibata-cursors
            hyfetch
            bpytop
            ckan
            steam
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

    # proton directory fix
    home.activation.linkProtonGE = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.steam/root/compatibilitytools.d"
        run ln -sfn "${pkgs.proton-ge-bin.steamcompattool}" "$HOME/.steam/root/compatibilitytools.d/GE-Proton-nix"
        '';

    # assetto corsa fonts symlink
    home.activation.linkFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "${acFontsDir}" ]; then
            for f in ${fontsDir}/*.ttf; do
                run ln -sfn "$f" "${acFontsDir}/$(basename "$f")"
            done
        fi
    '';
}
