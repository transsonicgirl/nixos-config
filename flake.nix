{
  description = "transsonicgirl's NixOS configuration (morpheus + trinity)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      mkHost = hostName: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/common.nix
            ./modules/boot-grub.nix
            ./modules/desktop.nix
            ./modules/packages.nix
            ./modules/dev.nix
            ./hosts/${hostName}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.transsonicgirl = import ./home/transsonicgirl.nix;
            }
          ] ++ extraModules;
        };
    in {
      nixosConfigurations = {
        morpheus = mkHost "morpheus" [ ];
        trinity  = mkHost "trinity"  [ ];
      };
    };
}
