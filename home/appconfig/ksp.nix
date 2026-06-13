# home/appconfig/ksp.nix
{ config, pkgs, ... }:
let
  kspDir = "/home/transsonicgirl/WOPR/SteamLibrary/steamapps/common/Kerbal Space Program";

  kspWrapper = pkgs.buildFHSEnv {
    name = "ksp-wrapper";
    targetPkgs = pkgs: with pkgs; [
      # Core runtime
      glibc
      libgcc.lib
      gcc-unwrapped.lib

      # Mono — KSPBurst needs bcl.exe via system mono
      mono

      # Graphics — RADV/Vulkan + OpenGL for RX 7800 XT
      mesa
      libGL
      libGLU
      vulkan-loader
      vulkan-tools
      libdrm
      libxkbcommon

      # 32-bit graphics (Unity needs these)
      pkgsi686Linux.mesa
      pkgsi686Linux.libGL

      # Audio
      openal
      pipewire
      alsa-lib

      # SDL / input
      SDL2
      udev
      libevdev

      # System libs KSP's Unity runtime needs
      dbus
      freetype
      curl
      libpng
      zlib
      expat
      nspr
      nss

      # X11 (Unity 2019 renders through XWayland)
      libx11
      libxcursor
      libxrandr
      libxi
      libxext
      libxfixes
      libxrender
      libxcb
      xorg.libXScrnSaver

      # Fonts — Unity's dynamic font rasterizer (KER, stock dV readouts)
      # needs fontconfig + actual font files visible in the sandbox.
      fontconfig
      dejavu_fonts
      liberation_ttf
      noto-fonts

      # Alternate allocator — preloaded to bypass glibc 2.42's hardened
      # malloc, which aborts on KSPBurst's native allocation patterns.
      jemalloc
    ];

    runScript = pkgs.writeShellScript "ksp-launch" ''
      unset STEAM_RUNTIME
      unset LD_PRELOAD

      # Preload jemalloc to replace glibc's allocator. KSPBurst's native
      # Burst code triggers glibc 2.42's "invalid size (unsorted)" abort;
      # jemalloc has no such integrity assertions, so the crash goes away
      # while Burst stays fully functional (Parallax colliders, Waterfall).
      export LD_PRELOAD="${pkgs.jemalloc}/lib/libjemalloc.so"

      # Mono — for KSPBurst's bcl.exe
      export MONO_PATH="${pkgs.mono}/lib/mono/4.5"
      export PATH="${pkgs.mono}/bin:$PATH"

      # Pass session display env through to the sandbox.
      # buildFHSEnv strips these, so re-export explicitly.
      export DISPLAY="''${DISPLAY:-:0}"
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/1000}"

      # Force XWayland — Unity 2019 is unreliable on native Wayland.
      unset WAYLAND_DISPLAY
      export SDL_VIDEODRIVER=x11

      # Build the fontconfig cache inside the sandbox so Unity's dynamic
      # font rasterizer can resolve glyphs (fixes blank KER/dV text).
      export FONTCONFIG_PATH=/etc/fonts
      fc-cache -f >/dev/null 2>&1 || true

      cd "${kspDir}"
      exec "${kspDir}/KSP.x86_64" -force-glcore "$@"
    '';
  };
in
{
  home.packages = [ kspWrapper ];
}
