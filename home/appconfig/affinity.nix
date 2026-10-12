# home/appconfig/affinity.nix
{ config, pkgs, lib, ... }:
let
  # Affinity under Wine can't re-dock torn-off panels, so manage the layout as text instead
  affinityLayout = pkgs.writeShellScriptBin "affinity-layout" ''
    exec ${pkgs.python3}/bin/python3 ${./affinity-layout.py} "$@"
  '';
in
{
  home.packages = [ affinityLayout ];

  # out-of-store so edits to the repo copy apply without a rebuild
  xdg.configFile."affinity/photo-layout.txt".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/appconfig/photo-layout.txt";

  # Film LUTs as drive L:, plus folders under Favorites in Wine's file dialog
  # (name shown in the dialog -> folder on disk). These live in the writable
  # overlay layer of Affinity's prefix, so changes show up after a full restart
  # of Affinity (including its leftover wineserver).
  home.activation.affinityLuts = lib.hm.dag.entryAfter [ "writeBoundary" ] (let
    luts = "${pkgs.film-luts}/share/luts/pat-david";
    prefix = "$HOME/.local/share/affinity";
    favoritesDir = "${prefix}/drive_c/users/${config.home.username}/Favorites";
    favorites = {
      "Film LUTs" = luts;
      "Photos" = "${config.home.homeDirectory}/Violet/tank/photos";
    };
  in ''
    run mkdir -p "${prefix}/dosdevices" "${favoritesDir}"
    run ln -sfn "${luts}" "${prefix}/dosdevices/l:"
  '' + lib.concatStrings (lib.mapAttrsToList (name: target: ''
    run ln -sfn "${target}" "${favoritesDir}/${name}"
  '') favorites));
}
