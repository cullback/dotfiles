# Navidrome music server. Music lives on the local ZFS pool at /storage/media/Music.
# State in /var/lib/navidrome. Bound to 0.0.0.0 for LAN/Tailscale testing during the
# migration; tighten to 127.0.0.1 behind Caddy at cutover (Phase 5).
{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/storage/media/music";
    };
  };

  # Don't start until the local ZFS media dataset is mounted.
  systemd.services.navidrome = {
    after = [ "zfs-mount.service" ];
    wants = [ "zfs-mount.service" ];
  };
}
