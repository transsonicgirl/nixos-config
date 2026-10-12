{
    description = "transsonicgirl's NixOS configuration (morpheus + trinity)";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        affinity-nix.url ="github:mrshmllow/affinity-nix";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:
        let
        system = "x86_64-linux";

    mkHost = hostName: extraModules:
        nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [
                ./modules/auto-update.nix
                ./modules/boot-grub.nix
                ./modules/config.nix
                ./modules/desktop.nix
                ./modules/dev.nix
                ./modules/packages.nix
                ./modules/system.nix
                ./hosts/${hostName}
                home-manager.nixosModules.home-manager
                sops-nix.nixosModules.sops
                {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.extraSpecialArgs = { inherit inputs; };
                    home-manager.users.transsonicgirl = import ./home/transsonicgirl.nix;
                    nixpkgs.overlays = [
                        inputs.affinity-nix.overlays.default
                        (final: prev: {
                         bpytop = final.callPackage ./pkgs/bpytop.nix {};
                         kasane-teto-cursor = final.callPackage ./pkgs/kasane-teto-cursor {};
                         film-luts = final.callPackage ./pkgs/film-luts {};
                         })
                    ];
                }
                ({ pkgs, ... }: {
                })
            ] ++ extraModules;
        };
    in {
        nixosConfigurations = {
            morpheus = mkHost "morpheus" [ ];
            trinity  = mkHost "trinity"  [ ];
        };
    };
}
