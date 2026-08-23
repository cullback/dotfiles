# Navidrome music server on crimson. Scans the curated music folder
# (/srv/media/music/curated) via the read-only /srv/media bind of frost/vault/media
# (see jellyfin.nix) - tags are the source of truth. State in /var/lib/navidrome.
# Public access goes only through Caddy; the backend itself is loopback-only.
{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = false;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      MusicFolder = "/srv/media/music/curated";
    };
  };

  # Don't start until the media bind mount is up.
  systemd.services.navidrome = {
    after = [ "srv-media.mount" ];
    requires = [ "srv-media.mount" ];
    serviceConfig = {
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProcSubset = "pid";
      ProtectProc = "invisible";
      RemoveIPC = true;
      RestrictSUIDSGID = true;
    };
  };
}
