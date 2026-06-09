{ config, pkgs, ... }:
let
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
    runScript = pkgs.writeScript "ksp-launch" ''
        #!/bin/sh
        exec "/home/transsonicgirl/WOPR/SteamLibrary/steamapps/common/Kerbal Space Program/KSP.x86_64" "$@"
    '';
};
in
{
    home.packages = [ kspWrapper ];
}
