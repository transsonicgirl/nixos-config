{ lib, stdenvNoCC, fetchzip }:
stdenvNoCC.mkDerivation rec {
    pname = "ioskeley-mono";
    version = "2.2.0";

    # Nerd Font build: families "IoskeleyMono Nerd Font" and
    # "IoskeleyMono Nerd Font Mono" (single-width icons, for terminals)
    src = fetchzip {
        url = "https://github.com/ahatem/IoskeleyMono/releases/download/v${version}/IoskeleyMono-NerdFont.zip";
        hash = "sha256-58wKG9DnaGKBdqjhue3hd9QEIHTBB6u4vExKCFKTt5g=";
        stripRoot = false;
    };

    # Normal width only; the SemiCondensed set shares the family name
    installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp Normal/*.ttf $out/share/fonts/truetype/
    '';

    meta = {
        description = "Programming typeface built on Iosevka, Nerd Font patched";
        homepage = "https://github.com/ahatem/IoskeleyMono";
        license = lib.licenses.ofl;
        platforms = lib.platforms.all;
    };
}
