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
            name = "KasaneTeto";
            package = pkgs.kasane-teto-cursor;
            hyprcursor.enable = true;
            size = 24;
        };
        packages = with pkgs; [
            bibata-cursors
            hyfetch
            bpytop
            ckan
            steam
            gh          # GitHub CLI — required by octo.nvim for PR/issue review
        ];

    };

    programs.home-manager.enable = true;
  
    xdg.configFile."nvim" = {
      source = ./nvim;
      recursive = true;
    };

    home.sessionVariables = {
        EDITOR = "nvim";
    };
  
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        fish_add_path /opt/riscv/bin
      '';
    };

    programs.ssh = {
        enable = true;
        settings = {
            "*" = {
                ForwardAgent = false;
                AddKeysToAgent = "no";
                Compression = false;
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts = false;
                UserKnownHostsFile = "~/.ssh/known_hosts";
                ControlMaster = "no";
                ControlPath = "~/.ssh/master-%r@%n:%p";
                ControlPersist = "no";
            };

            violet = {
                HostName = "100.105.138.60";
                User = "root";
                ServerAliveInterval = 60;
                ServerAliveCountMax = 10;
            };
        };
    };
  
    programs.git = {
      enable = true;
      settings.user.name  = "Allison Byrnes";
      settings.user.email = "allison.byrnes42@gmail.com";
      settings.init.defaultBranch = "main";
    };
  
    xdg.configFile."hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${inputs.self}/home/dotfiles/hypr";
    xdg.configFile."waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${inputs.self}/home/dotfiles/waybar";
  
    programs.kitty = lib.mkForce {
        enable = true;
        settings = {
            term = "xterm-256color";
        };
    };


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
