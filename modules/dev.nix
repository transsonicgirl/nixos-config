{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core build
    gcc
    gnumake
    cmake
    pkg-config
    binutils
    gdb
    valgrind
    bear

    # Languages / toolchains
    python3
    nodejs_22
    go
    rustup
    jdk
    mono
    swift

    # Embedded — matches the arm-none-eabi + riscv + openocd stuff on morpheus
    gcc-arm-embedded
    openocd
    minicom
    verilator
    iverilog
    gtkwave

    # Editors / tooling
    neovim
    vscode
    git
    git-lfs
    tree-sitter
    lua-language-server
    nil # Nix LSP

    # Sysadmin / net
    nmap
    traceroute
    bind.dnsutils
    strace
    file
    which
  ];

  # Virt / containers — Arch had gnome-boxes; provide libvirt as the backend.
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
