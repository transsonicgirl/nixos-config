# DEV.NIX
# Devel tools
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
    # python3 carries debugpy (for nvim-dap-python) + pylsp (Python LSP) so
    # a bare `python3` invocation finds both.
    (python3.withPackages (ps: with ps; [
      debugpy
      python-lsp-server
    ]))
    nodejs_22
    go
    rustup
    jdk
    mono

    # Embedded
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
    claude-code

    # Language servers (native/patchelf'd — replaces the broken mason binaries)
    lua-language-server        # lua_ls
    nil                        # nil_ls (Nix)
    clang-tools                # clangd + clang-format + clang-tidy
    rust-analyzer              # rust_analyzer
    cmake-language-server      # cmake
    harper                     # harper_ls (prose/grammar for notes & markdown)
    # pylsp comes from the python3.withPackages above

    # Formatters (used by none-ls). fish_indent ships with fish; clang-format
    # comes from clang-tools above.
    stylua                     # lua
    black                      # python
    isort                      # python
    shfmt                      # bash / sh

    # Sysadmin / net
    nmap
    traceroute
    bind.dnsutils
    strace
    file
    which
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
