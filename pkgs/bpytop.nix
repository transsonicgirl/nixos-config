{ lib, pkgs, python3Packages }:

python3Packages.buildPythonApplication {
    pname = "bpytop";
    version = "1.0.68";

    src = pkgs.fetchFromGitHub {
        owner = "aristocratos";
        repo = "bpytop";
        rev = "v1.0.68";
        hash = "sha256-NHfaWWwNpGhqu/ALcW4p4X6sktEyLbKQuNHpAUUw4LY=";
    };

    format = "other";

    installPhase = ''
        mkdir -p $out/bin
        cp bpytop.py $out/bin/bpytop
        chmod +x $out/bin/bpytop
        substituteInPlace $out/bin/bpytop \
            --replace "#!/usr/bin/env python3" "#!${python3Packages.python.interpreter}"
    '';

    propagatedBuildInputs = with python3Packages; [
        psutil
    ];

    meta = {
        description = "A TUI system monitor.";
        homepage = "github.com/aristocratos/bpytop";
        license = lib.licenses.asl20;
        mainProgram = "bpytop";
    };
}
