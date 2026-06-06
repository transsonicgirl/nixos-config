{ pkgs, ... }:
{
  home.username = "transsonicgirl";
  home.homeDirectory = "/home/transsonicgirl";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

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
    userName  = "transsonicgirl";
    userEmail = "itemboxes2004@gmail.com";
  };

  programs.kitty.enable = true;
}
