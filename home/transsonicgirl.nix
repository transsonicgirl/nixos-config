{ inputs, config, pkgs, lib, ... }:
let
     fontsDir = ./assets/fonts;
     acFontsDir = "$HOME/WOPR/SteamLibrary/steamapps/compatdata/244210/pfx/drive_c/windows/Fonts/";
in
{
    imports = [
        ./appconfig/ksp.nix
        ./appconfig/affinity.nix
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
            math-preview  # MathJax renderer for Emacs' inline LaTeX (math-preview.el)
        ];

    };

    programs.home-manager.enable = true;
  
    xdg.configFile."nvim" = {
      source = ./nvim;
      recursive = true;
    };

    # Emacs: packages come from Nix (not package.el), init.el only configures
    # them. pgtk = native Wayland build for Hyprland.
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      extraPackages = epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
        no-littering
        catppuccin-theme
        nerd-icons
        doom-modeline
        indent-bars
        undo-fu
        evil
        evil-collection
        evil-mc
        general
        vertico
        orderless
        marginalia
        consult
        treesit-auto
        nix-ts-mode
        markdown-mode
        mixed-pitch
        math-preview
        corfu
        apheleia
        nerd-icons-dired
        dired-subtree
        dired-sidebar
        magit
        diff-hl
        dashboard
        claude-code   # yuya373/claude-code-emacs (runs the CLI in vterm)
      ];
    };

    xdg.configFile."emacs" = {
      source = ./emacs;
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
        enableDefaultConfig = false;
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
                HostName = "100.126.212.6";
                User = "transsonicgirl";
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

    # film simulation .cube LUTs for Affinity Photo (Layer > New Adjustment > LUT)
    home.file."Pictures/LUTs/Pat David Film".source =
      "${pkgs.film-luts}/share/luts/pat-david";
  
    programs.kitty = lib.mkForce {
        enable = true;
        settings = {
            term = "xterm-256color";
            # Not relevant for a tiling wm
            remember_window_size = "no";
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
