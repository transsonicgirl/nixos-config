{ lib, stdenvNoCC, fetchzip, python3 }:
stdenvNoCC.mkDerivation {
    pname = "film-luts";
    version = "2015-09-20";

    # RawTherapee Film Simulation Collection (Pat David et al.), Hald CLUT PNGs
    src = fetchzip {
        url = "https://rawtherapee.com/shared/HaldCLUT.zip";
        hash = "sha256-WCu4h9/ZVPqJzACzEjcVv0xt4F8WrSjUFISi/1uhe9c=";
        stripRoot = false;
    };

    nativeBuildInputs = [ (python3.withPackages (ps: [ ps.numpy ps.pillow ])) ];

    dontConfigure = true;
    buildPhase = ''
        python3 ${./hald2cube.py} HaldCLUT cube 33
    '';
    installPhase = ''
        mkdir -p $out/share/luts
        cp -r cube $out/share/luts/pat-david
        cp HaldCLUT/README.txt $out/share/luts/pat-david/
    '';

    meta = {
        description = "RawTherapee film simulation Hald CLUTs converted to .cube";
        homepage = "https://rawpedia.rawtherapee.com/Film_Simulation";
        license = lib.licenses.cc-by-sa-40;
    };
}
