{ lib, stdenvNoCC, python3 }:

stdenvNoCC.mkDerivation {
    pname = "moza-fh6-shim";
    version = "0.1.0";

    src = ./.;
    dontBuild = true;

    installPhase = ''
        runHook preInstall

        mkdir -p $out/bin

        cp moza_fh6_shim.py $out/bin/moza-fh6-shim
        substituteInPlace $out/bin/moza-fh6-shim \
            --replace "#!/usr/bin/env python3" "#!${python3.interpreter}"
        chmod +x $out/bin/moza-fh6-shim

        cp moza-fh6-wrap.sh $out/bin/moza-fh6-wrap
        substituteInPlace $out/bin/moza-fh6-wrap \
            --subst-var-by shim "$out/bin/moza-fh6-shim"
        chmod +x $out/bin/moza-fh6-wrap

        runHook postInstall
    '';

    meta = {
        description = "Re-expose a MOZA R5 with its pedals on the HID usages Forza Horizon 6 expects";
        longDescription = ''
            Wine's SDL backend maps SDL axis index through a fixed usage table,
            and SDL enumerates in evdev code order. The R5 interleaves four dead
            axes among its live ones, so its accelerator lands on HID usage Z
            while usage Y -- where a driving game reads the accelerator -- is a
            dead axis. This mirrors the wheel onto a uinput device whose six
            axes are ordered to come out as X/Y/Z/Rz, matching the layout Wine's
            own g920_absolute_usages table documents.

            Input only; force feedback is not relayed yet.
        '';
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
        mainProgram = "moza-fh6-shim";
    };
}
