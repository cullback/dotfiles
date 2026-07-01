# Navidrome music server on crimson. Scans the whole music library via the read-only
# /srv/media bind of frost/vault/media (see jellyfin.nix) - tags are the source of
# truth, so the folder tiers don't matter. State in /var/lib/navidrome. Reachable on
# the LAN/Tailscale at http://crimson:4533 and public via Caddy at music.benburk.ca.
{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/srv/media/music";
    };
  };

  # Don't start until the media bind mount is up.
  systemd.services.navidrome = {
    after = [ "srv-media.mount" ];
    requires = [ "srv-media.mount" ];
  };
}
