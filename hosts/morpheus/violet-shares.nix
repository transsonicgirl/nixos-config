{ config, lib, ... }:
# SMB shares from violet, mounted under ~/Violet/ at their real server paths,
# so ~/Violet/tank/photos is /tank/photos on the server.
#
# The share list mirrors `shares.exports` in ~/code/server-nixos/modules/shares.nix.
# Share NAME (what goes in the UNC path) and server PATH are different things:
# the `photos` share is //violet/photos, which serves /tank/photos.
#
# Credentials come from sops (secrets/desktop.yaml), rendered at activation to
# a root-only file under /run (tmpfs). Nothing plaintext lives in the repo, the
# Nix store, or on disk. Edit the password with:
#   nix run nixpkgs#sops -- secrets/desktop.yaml
let
  home = "/home/transsonicgirl";

  # LAN address. Violet's `hosts allow` also admits the tailnet, so swapping
  # this for 100.126.212.6 works away from home — but then add
  # "x-systemd.after=tailscaled.service" to the options below.
  server = "violet";

  # share name -> path on violet
  shares = {
    media = "/tank/media";
    books = "/tank/books";
    photos = "/tank/photos";
    docs = "/tank/docs";
    scratch = "/tank/scratch";
  };

  mkMount = name: path: lib.nameValuePair "${home}/Violet${path}" {
    device = "//${server}/${name}";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."violet-smb-credentials".path}"
      # Violet sets `server min protocol = SMB3`; say so rather than rely on
      # cifs-utils negotiating it.
      "vers=3.1.1"
      # Without these every file shows up as root-owned.
      "uid=1000" "gid=100"
      "file_mode=0664" "dir_mode=0775"
      # Mount on first access instead of at boot: a down server can't hang
      # boot, and by first access sops-nix has rendered the credentials file.
      "x-systemd.automount" "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"
      "x-systemd.after=tailscaled.service"
    ];
  };
in
{
  sops = {
    defaultSopsFile = ../../secrets/desktop.yaml;
    # Decrypt with a key derived from the host's SSH key — nothing extra to
    # provision or back up. Same approach as violet.
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets.violet-smb-password = { };

    # mount.cifs wants `username=`/`password=` lines, the secret is the bare
    # password; the template wraps it at activation time.
    templates."violet-smb-credentials".content = ''
      username=transsonicgirl
      password=${config.sops.placeholder.violet-smb-password}
    '';
  };

  fileSystems = lib.mapAttrs' mkMount shares;
}
