{ stdenv }:
stdenv.mkDerivation {
    pname = "kasane-teto-cursor";
    version = "1.0";
    src = ./.;
    dontBuild = true;
    installPhase = '' 
        mkdir -p $out/share/icons/KasaneTeto
        cp -r cursor.theme index.theme cursors $out/share/icons/KasaneTeto/
    '';
}
