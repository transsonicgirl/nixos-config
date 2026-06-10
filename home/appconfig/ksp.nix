{ config, pkgs, ... }:

let
  kspDir = "/home/transsonicgirl/WOPR/SteamLibrary/steamapps/common/Kerbal Space Program";
  kspLaunch = pkgs.writeShellScript "ksp-launch" ''
    cd "${kspDir}"
    exec "${kspDir}/KSP.x86_64" "$@"
  '';
  kspWrapper = pkgs.buildFHSEnv {
    name = "ksp-wrapper";
    targetPkgs = pkgs: with pkgs; [
      glibc
      libgcc
      mesa
      libGL
      SDL2
      udev
      dbus
      freetype
      openal
      curl
    ];
    runScript = "${kspLaunch}";
  };
in
{
  home.packages = [ kspWrapper ];
}
