{ config, ... }
{
    system.autoUpgrade = {
        enable = true;
        flake == "/etc/nixos/nixos-config/flake.nix";
        flags = [
            "--update-input" "nixpkgs"
            "--commit-lock-file"
        ];
        dates = "weekly"
        allowReboot = false;
    }
}
