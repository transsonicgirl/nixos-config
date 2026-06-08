# CONFIG.NIX
# Overall nix-level config, system version
{ pkgs, ... }:
{
    system.stateVersion = "26.05";

    nixpkgs.config.allowUnfree = true;

    nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
    };

    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
    };

}
