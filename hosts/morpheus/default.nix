{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "morpheus";

  # AMD GPU (Radeon RX 7800 XT + iGPU on Granite Ridge).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ 
        rocmPackages.clr.icd 
        mesa
    ];
    extraPackages32 = with pkgs; [
        pkgsi686Linux.mesa
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Desktop-only services from the Arch dump.
  hardware.openrazer.enable = true;   # Razer mouse dock + polychromatic

  # MOZA R5 wheelbase.
  #
  # Forza Horizon 6 reads the accelerator from HID usage Y, but Wine's SDL
  # backend maps SDL axis *index* through a fixed usage table and the R5
  # interleaves dead axes among its live ones, so usage Y lands on a dead axis
  # and the game sees no usable wheel. This re-exposes it with the pedals on
  # the usages a driving game expects.
  #
  # Not enabled globally: set the game's Steam launch options to
  #   moza-fh6-wrap %command%
  # which runs the shim only for as long as the game does.
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/moza-fh6-shim { })
  ];

  # Wired NIC (Realtek r8169 enp8s0).
  #
  # ⚠️ `networking.interfaces.enp8s0.useDHCP = true` WAS SET HERE AND STARTED A
  # SECOND DHCP CLIENT. NetworkManager (modules/system.nix) already manages this
  # interface, and that option pulls in dhcpcd alongside it — two clients on one
  # link, both processing router advertisements.
  #
  # Symptoms, measured 2026-09-14:
  #   - dhcpcd rewrote the IPv6 route every ~3 s, forever:
  #       enp8s0: changing route to 2601:602:8083:8990::/64
  #       enp8s0: changing default route via fe80::e6bf:faff:fe89:cd6c
  #   - dhcpcd owned the link's DNS in systemd-resolved, so resolved held ONLY
  #     the ISP's RA-advertised servers (2001:558:feed::1/::2) while
  #     NetworkManager's DHCPv4 entry — 192.168.0.41, the Pi-hole — never made
  #     it in. Net effect: every lookup bypassed Pi-hole.
  #
  # Neither showed up in `systemctl --failed`; dhcpcd sat there `active`.
  #
  # NetworkManager does DHCP on its own, so this needs nothing here.
  networking.useDHCP = false;

  # Ignore DNS servers learned from IPv6 router advertisements.
  #
  # The Xfinity gateway (Vantiva XB7/XB8) advertises Comcast's resolvers via
  # RDNSS and offers no way to change or suppress that — RA DNS is additive by
  # design, so there is no "my server supersedes yours". Without this, resolved
  # keeps both Pi-hole (from DHCPv4) and Comcast (from RA) and picks by its own
  # heuristics, which in practice meant Comcast and no filtering at all.
  #
  # IPv4 auto-DNS stays ON, so Pi-hole still arrives via the DHCP lease. IPv6
  # connectivity is unaffected — only DNS learned over RA is discarded.
  #
  # This is a per-client workaround for a LAN-wide problem. The real fix is
  # taking the gateway out of the routing role (bridge mode, or violet as
  # router); until then every other device on the LAN still bypasses Pi-hole.
  networking.networkmanager.connectionConfig = {
    "ipv6.ignore-auto-dns" = true;
  };

  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
}
