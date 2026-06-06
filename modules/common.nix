{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.networkmanager.enable = true;
  networking.useDHCP = false;

  services.openssh.enable = true;
  services.tailscale.enable = true;

  programs.fish.enable = true;

  users.users.transsonicgirl = {
    isNormalUser = true;
    description = "transsonicgirl";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "dialout" "plugdev" ];
    shell = pkgs.fish;
  };

  # Pin a state version once you do your first install. Don't bump casually.
  system.stateVersion = "25.05";
}
